#import "MTKWebRTCVideoView.h"
#import "Log.h"

@implementation MTKWebRTCVideoView
{
    id<MTLDevice> _metalDevice;
    id<MTLCommandQueue> _metalDeviceCommandQueue;
    id<MTLTexture> _yTexture;
    id<MTLTexture> _uTexture;
    id<MTLTexture> _vTexture;
    CVMetalTextureCacheRef _textureCache;
    id<MTLComputePipelineState> _computePipelineState;
    int _width;
    int _height;
}

- (nonnull instancetype)initWithFrame:(CGRect)frameRect device:(nullable id<MTLDevice>)device
{
    self = [super initWithFrame:frameRect device:device];

    if (self)
    {
        [self initialize];
    }

    return self;
}

- (nonnull instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        [self initialize];
    }

    return self;
}

-(void)initialize
{
    _metalDevice = MTLCreateSystemDefaultDevice();
    _metalDeviceCommandQueue = [_metalDevice newCommandQueue];
    
    self.device = _metalDevice;
    self.clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.framebufferOnly = NO;
    
    id<MTLLibrary> library = [_metalDevice newDefaultLibrary];
    id<MTLFunction> function = [library newFunctionWithName:@"YCbCrColorConversion"];
    NSError *error = nil;
    _computePipelineState = [_metalDevice newComputePipelineStateWithFunction:function error:&error];
    CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _metalDevice, nil, &_textureCache);
}

- (void)setSize:(CGSize)size
{
}

void CopyPlane(const uint8_t *source, int sourceStride, uint8_t *destination, size_t destinationStride, int height)
{
    if (sourceStride == destinationStride)
    {
        memcpy(destination, source, sourceStride * height);
    }
    else
    {
        for (int line = 0; line < height; ++line)
        {
            memcpy(destination, source, sourceStride);
            source += sourceStride;
            destination +=destinationStride;
        }
    }
}

struct PixelBufferPlane
{
    PixelBufferPlane(CVPixelBufferRef pixelBuffer, size_t planeIndex) : _plane(reinterpret_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex))),
        _stride(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex)),
        _width(CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)),
        _height(CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex))
                                                                               
    {
    }
    
    uint8_t *_plane;
    size_t _stride;
    size_t _width;
    size_t _height;
};

- (void)renderFrame:(nullable RTCVideoFrame *)frame
{
    id<RTCVideoFrameBuffer> buffer = frame.buffer;
    if (buffer)
    {
        id<RTCI420Buffer> i420Buffer = [buffer toI420];
        CVPixelBufferRef pixelBuffer = nil;
        NSDictionary* attributes =
        @{
            (NSString*)kCVPixelBufferMetalCompatibilityKey: @YES
        };
        CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                              i420Buffer.width,
                                              i420Buffer.height,
                                              kCVPixelFormatType_420YpCbCr8Planar,
                                              (__bridge CFDictionaryRef)attributes,
                                              &pixelBuffer);
        if (result != kCVReturnSuccess)
        {
            DDLogError(@"CVPixelBufferCreate() failed with %d", result);
            return;
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        PixelBufferPlane yPlane(pixelBuffer, 0), uPlane(pixelBuffer, 1), vPlane(pixelBuffer, 2);
        CopyPlane(i420Buffer.dataY, i420Buffer.strideY, yPlane._plane, yPlane._stride, i420Buffer.height);
        CopyPlane(i420Buffer.dataU, i420Buffer.strideU, uPlane._plane, uPlane._stride, i420Buffer.chromaHeight);
        CopyPlane(i420Buffer.dataV, i420Buffer.strideV, vPlane._plane, vPlane._stride, i420Buffer.chromaHeight);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVMetalTextureRef texture = nil;
        result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, i420Buffer.width, i420Buffer.height, 0, &texture);
        if (result != kCVReturnSuccess)
        {
            DDLogError(@"CVMetalTextureCacheCreateTextureFromImage() failed with %d", result);
            return;
        }
        _yTexture = CVMetalTextureGetTexture(texture);
        result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, i420Buffer.chromaWidth, i420Buffer.chromaHeight, 1, &texture);
        if (result != kCVReturnSuccess)
        {
            DDLogError(@"CVMetalTextureCacheCreateTextureFromImage() failed with %d", result);
            return;
        }
        _uTexture = CVMetalTextureGetTexture(texture);
        result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, i420Buffer.chromaWidth, i420Buffer.chromaHeight, 2, &texture);
        if (result != kCVReturnSuccess)
        {
            DDLogError(@"CVMetalTextureCacheCreateTextureFromImage() failed with %d", result);
            return;
        }
        _vTexture = CVMetalTextureGetTexture(texture);
        _width = i420Buffer.width;
        _height = i420Buffer.height;
        if (self.drawableSize.width != _width || self.drawableSize.height != _height)
        {
            self.drawableSize = CGSize { .width = static_cast<double>(_width), .height = static_cast<double>(_height) };
        }
        [self render];
    }
}

- (void)render
{
    if (_yTexture && _uTexture && _vTexture)
    {
        id<MTLCommandBuffer> commandBuffer = _metalDeviceCommandQueue.commandBuffer;
        id<MTLComputeCommandEncoder> commandEncoder = commandBuffer.computeCommandEncoder;
        [commandEncoder setComputePipelineState:_computePipelineState];
        [commandEncoder setTexture:_yTexture atIndex:0];
        [commandEncoder setTexture:_uTexture atIndex:1];
        [commandEncoder setTexture:_vTexture atIndex:2];
        [commandEncoder setTexture:self.currentDrawable.texture atIndex:3];
        NSUInteger groupWidth = _computePipelineState.threadExecutionWidth, groupHeight = _computePipelineState.maxTotalThreadsPerThreadgroup / groupWidth;
        MTLSize threadsPerThreadgroup = MTLSizeMake(groupWidth, groupHeight, 1), groups = MTLSizeMake((_width + threadsPerThreadgroup.width - 1)  / threadsPerThreadgroup.width,
                                                                                                   (_height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                                                                                   1);
        [commandEncoder dispatchThreadgroups:groups threadsPerThreadgroup:threadsPerThreadgroup];
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:self.currentDrawable];
        [commandBuffer commit];
        _yTexture = nil;
        _uTexture = nil;
        _vTexture = nil;
    }
}

@end
