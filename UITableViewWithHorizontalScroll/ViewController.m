//
//  ViewController.m
//  UITableViewWithHorizontalScroll
//
//  Created by Dipen Panchasara on 24/06/16.
//  Copyright © 2016 Company Name. All rights reserved.
//

#import "ViewController.h"
#import "ListCell.h"
#import "ItemCell.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *arrItems;
    
    NSURLSessionConfiguration *sessionConfiguration;
    NSURLSession *session;
    
    NSMutableDictionary *dictDownloadTracking;
    NSCache *cache;
}

@property (nonatomic, strong) NSArray *arrItems;
@property (nonatomic, strong) NSMutableDictionary *contentOffsetDictionary;

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSMutableDictionary *dictDownloadTracking;
@property (nonatomic, strong) NSCache *cache;

@end

@implementation ViewController

@synthesize arrItems;

@synthesize sessionConfiguration, session;
@synthesize dictDownloadTracking, cache;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *err = nil;
    self.arrItems = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
    if(err)
    {
        NSLog(@"%@",err.localizedDescription);
    }
    
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    
    // Do any additional setup after loading the view.
    self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.sessionConfiguration.timeoutIntervalForResource = 60;
    self.sessionConfiguration.timeoutIntervalForResource = 120;
    self.sessionConfiguration.requestCachePolicy =  NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    
    self.dictDownloadTracking = [NSMutableDictionary dictionary];
    
    self.cache = [[NSCache alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.arrItems.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return self.arrItems.count;
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListCell";
    
    ListCell *cell = (ListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[ListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(ListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
    NSInteger index = cell.collectionView.indexPath.row;
    
    CGFloat horizontalOffset = [self.contentOffsetDictionary[[@(index) stringValue]] floatValue];
    [cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0)];
}

#pragma mark - UITableViewDelegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 130;
}

#pragma mark - UICollectionViewDataSource Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
//    NSArray *collectionViewArray = self.arrItems[[(IndexedCollectionView *)collectionView indexPath].row];
    return self.arrItems.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ItemCell *cell = (ItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:IndexedCollectionViewCellIdentifier forIndexPath:indexPath];
    
    if(cell == nil)
    {
        NSLog(@"cell is nil.");
    }
    
    NSDictionary *dict = self.arrItems[indexPath.row];
    cell.lblTitle.text = [NSString stringWithFormat:@"%@",dict[@"title"]];
    
    NSString *thumbnailURL = dict[@"thumbnailurl"];
    NSString *photoId = dict[@"id"];
    
    if(thumbnailURL)
    {
        if([self.cache objectForKey:photoId])
        {
            NSLog(@"loaded from cache.");
            [cell.ivThumb setImage:[self.cache objectForKey:photoId]];
        }
        else
        {
            if(!self.dictDownloadTracking[photoId])
            {
                NSURL *url = [NSURL URLWithString:[thumbnailURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {

                    if(error)
                    {
                        NSLog(@"%@",error.localizedDescription);
                        [self.dictDownloadTracking removeObjectForKey:photoId];
                        return;
                    }
                    
                    NSData *data = [NSData dataWithContentsOfURL:location];
                    
                    [self.dictDownloadTracking removeObjectForKey:photoId];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ItemCell *cell = (ItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
                        
                        UIImage *img = [UIImage imageWithData:data];
                        
                        [self.cache setObject:img forKey:photoId];
                        
                        [cell.ivThumb setImage:img];
                    });
                }];
                
                [task resume];
                
                [self.dictDownloadTracking setObject:task forKey:photoId];
            }
            else
            {
                NSLog(@"Already in download.");
            }
        }
        
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UIScrollViewDelegate Methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![scrollView isKindOfClass:[UICollectionView class]]) return;
    
    CGFloat horizontalOffset = scrollView.contentOffset.x;
    
    IndexedCollectionView *collectionView = (IndexedCollectionView *)scrollView;
    NSInteger index = collectionView.indexPath.row;
    self.contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
}


@end
