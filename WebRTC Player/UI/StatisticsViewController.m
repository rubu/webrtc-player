#import "StatisticsViewController.h"
#import "PlaybackViewController.h"

#import <WebRTC/WebRTC.h>

@interface ChangeSet : NSObject
-(instancetype)initWithAdded:(NSArray<id>*)added removed:(NSArray<id>*)removed updated:(NSArray<id>*)updated;

-(NSArray<id>*)added;
-(NSArray<id>*)removed;
-(NSArray<id>*)updated;
@end

@implementation ChangeSet
{
NSArray<id> *_added;
NSArray<id> *_removed;
NSArray<id> *_updated;
}

-(instancetype)initWithAdded:(NSArray<id>*)added removed:(NSArray<id>*)removed updated:(NSArray<id>*)updated
{
    if (self = [super init])
    {
        _added = added;
        _removed = removed;
        _updated = updated;
    }
    return self;
}

-(NSArray<id>*)added
{
    return _added;
}

-(NSArray<id>*)removed
{
    return _removed;
}

-(NSArray<id>*)updated
{
    return _updated;
}
@end

@interface ReportValue : NSObject
-(instancetype)initWithKey:(NSString*)key
                     value:(NSString*)value;
-(NSString*)key;
-(void)setValue:(NSString*)value;
-(NSString*)value;
@end

@interface Report : NSObject
-(NSString*)id;
-(ReportValue*)reportAtIndex:(NSUInteger)index;
-(NSUInteger)reportCount;
-(ChangeSet*)updateWithReport:(RTCLegacyStatsReport*)report;
+(NSArray<Report*>*)fromReports:(NSArray<RTCLegacyStatsReport *> *)reports;
@end

@implementation Report
{
    NSMutableArray<ReportValue*> *_values;
    NSMutableDictionary<NSString* ,NSNumber*> *_valueIndexes;
    NSString *_id;
}

-(instancetype)initWithId:(NSString*)id
                  values:(NSMutableArray<ReportValue*>*)values
{
    if (self = [super init])
    {
        _id = id;
        _values = values;
        _valueIndexes = [NSMutableDictionary dictionary];
        unsigned int index = 0;
        for (ReportValue *value in _values)
        {
            [_valueIndexes setValue:[NSNumber numberWithInt:index] forKey:value.key];
            index++;
        }
    }
    return self;
}

-(NSString*)id
{
    return _id;
}

-(ReportValue*)reportAtIndex:(NSUInteger)index
{
    return [_values objectAtIndex:index];
}

-(NSUInteger)reportCount
{
    return _values.count;
}

-(ChangeSet*)updateWithReport:(RTCLegacyStatsReport*)report
{
    NSMutableArray<id> *added = [NSMutableArray array], *removed = [NSMutableArray array], *updated = [NSMutableArray array];
    for (NSString *key in report.values.allKeys)
    {
        NSString *value = [report.values valueForKey:key];
        NSNumber *valueIndex = [_valueIndexes objectForKey:key];
        if (valueIndex)
        {
            ReportValue *reportValue = [_values objectAtIndex:valueIndex.longValue];
            if ([reportValue.value isEqualToString:value] == NO)
            {
                [updated addObject:reportValue];
                reportValue.value = value;
            }
        }
        else
        {
            ReportValue *reportValue = [[ReportValue alloc] initWithKey:key value:value];
            [_values addObject:reportValue];
            [_valueIndexes setValue:[NSNumber numberWithLong:_values.count - 1] forKey:key];
            [added addObject:reportValue];
        }
    }
    return [[ChangeSet alloc] initWithAdded:added removed:removed updated:updated];
}

+(NSArray<Report*>*)fromReports:(NSArray<RTCLegacyStatsReport *> *)reports
{
    NSMutableArray<Report*> *reportNodes = [NSMutableArray arrayWithCapacity:reports.count];
    unsigned int index = 0;
    for (RTCLegacyStatsReport *report in reports)
    {
        NSMutableArray<ReportValue*> *values = [NSMutableArray array];
        for (NSString *key in report.values.allKeys)
        {
            [values addObject:[[ReportValue alloc] initWithKey:key value:[report.values objectForKey:key]]];
        }
        reportNodes[index++] = [[Report alloc] initWithId:report.reportId values:values];
    }
    return reportNodes;
}
@end

@implementation ReportValue
{
    NSString *_key;
    NSString *_value;
}

-(instancetype)initWithKey:(NSString*)key
                     value:(NSString*)value
{
    if (self = [super init])
    {
        _key = key;
        _value = value;
    }
    return self;
}

-(NSString*)key
{
    return _key;
}

-(void)setValue:(NSString*)value
{
    _value = value;
}

-(NSString*)value
{
    return _value;
}
@end

@interface Reports : NSObject
-(NSUInteger)count;
-(instancetype)initWithReports:(NSArray<RTCLegacyStatsReport *>*)reports;
-(Report*)objectAtIndex:(NSUInteger)index;
-(ChangeSet*)updateWithReports:(NSArray<RTCLegacyStatsReport *>*)reports;
@end

@implementation Reports
{
    NSArray<Report*> *_reports;
    NSMutableDictionary<NSString* ,NSNumber*> *_reportIndexes;
}

-(NSUInteger)count
{
    return _reports.count;
}

-(instancetype)initWithReports:(NSArray<RTCLegacyStatsReport *>*)reports;
{
    if (self = [super init])
    {
        _reports = [Report fromReports:reports];
        _reportIndexes = [NSMutableDictionary dictionary];
        unsigned int index = 0;
        for (Report *report in _reports)
        {
            [_reportIndexes setValue:[NSNumber numberWithInt:index] forKey:report.id];
            index++;
        }
    }
    return self;
}

-(Report*)objectAtIndex:(NSUInteger)index
{
    return [_reports objectAtIndex:index];
}

-(ChangeSet*)updateWithReports:(NSArray<RTCLegacyStatsReport *>*)reports
{
    NSMutableArray<id> *added = [NSMutableArray array], *removed = [NSMutableArray array], *updated = [NSMutableArray array];
    for (RTCLegacyStatsReport *report in reports)
    {
        NSNumber *reportIndex = [_reportIndexes objectForKey:report.reportId];
        if (reportIndex)
        {
            ChangeSet *changeSet = [[_reports objectAtIndex:reportIndex.longValue] updateWithReport:report];
            if (changeSet)
            {
                if (changeSet.added)
                {
                    [added addObjectsFromArray: changeSet.added];
                }
                if (changeSet.removed)
                {
                    [removed addObjectsFromArray: changeSet.removed];
                }
                if (changeSet.updated)
                {
                    [updated addObjectsFromArray: changeSet.updated];
                }
            }
        }
    }
    return [[ChangeSet alloc] initWithAdded:added removed:removed updated:updated];
}
@end

@interface StatisticsViewController ()

@end

@implementation StatisticsViewController
{
    RTCPeerConnection *_activePeerConnection;
    Reports *_reports;
}

-(void)refreshStatisticsUi:(NSArray<RTCLegacyStatsReport *> *)reports
{
    BOOL reload = _reports == nil || reports == nil;
    if (_reports == nil && reports)
    {
        _reports = [[Reports alloc] initWithReports:reports];
    }
    else if (reports == nil)
    {
        _reports = nil;
    }
    else
    {
        ChangeSet *changeSet = [_reports updateWithReports:reports];
        if (changeSet.added && changeSet.added.count)
        {
            [self.outlineView noteNumberOfRowsChanged];
        }
        if (changeSet.updated && changeSet.updated.count)
        {
            NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 1)];
            NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];
            for (id updated in changeSet.updated)
            {
                NSInteger rowIndex = [self.outlineView rowForItem:updated];
                [rowIndexes addIndex:rowIndex];
            }
            [self.outlineView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
        }
    }
    if (reload)
    {
        [self.outlineView reloadData];
    }
}

-(void)updateStatistics
{
    RTCPeerConnection *activePeerConnection = _activePeerConnection;
    if (activePeerConnection)
    {
        [activePeerConnection statsForTrack:nil statsOutputLevel:RTCStatsOutputLevelStandard completionHandler:^(NSArray<RTCLegacyStatsReport *> * _Nonnull stats)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshStatisticsUi:stats];
            });
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserverForName:kActiveRTCPeerConnectionChangedNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification)
    {
        self->_activePeerConnection = ((RTCPeerConnection*)notification.object);
        if (self->_activePeerConnection == nil)
        {
            [self refreshStatisticsUi:nil];
        }
    }];
    [NSTimer scheduledTimerWithTimeInterval:1.0
        target:self
        selector:@selector(updateStatistics)
        userInfo:nil
        repeats:YES];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
    NSInteger children = 0;
    if (item == nil && _reports)
    {
        children = _reports.count;
    }
    else if ([item isKindOfClass:[Report class]])
    {
        children = ((Report*)item).reportCount;
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
    if (item == nil && _reports)
    {
        return [_reports objectAtIndex:index];
    }
    else if ([item isKindOfClass:[Report class]])
    {
        return [((Report*)item) reportAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[Report class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *columnTitle = tableColumn.title;
    if ([item isKindOfClass:[Report class]])
    {
        if ([columnTitle isEqualToString:@"Report Id"])
        {
            return ((Report*)item).id;
        }
        return @"";
    }
    else if ([item isKindOfClass:[ReportValue class]])
    {
        if ([columnTitle isEqualToString:@"Key"])
        {
            return [(ReportValue*)item key];
        }
        else if ([columnTitle isEqualToString:@"Value"])
        {
            return [(ReportValue*)item value];
        }
        return @"";
    }
    return nil;
}
@end
