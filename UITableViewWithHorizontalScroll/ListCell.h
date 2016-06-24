//
//  ListCell.h
//  UITableViewWithHorizontalScroll
//
//  Created by Dipen Panchasara on 24/06/16.
//  Copyright © 2016 Company Name. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IndexedCollectionView : UICollectionView

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

static NSString *IndexedCollectionViewCellIdentifier = @"itemCell";

@interface ListCell : UITableViewCell

@property (retain) IBOutlet IndexedCollectionView *collectionView;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;

@end
