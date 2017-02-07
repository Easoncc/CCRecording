//
//  TUColorView.m
//  tataufo
//
//  Created by chenchao on 2016/12/13.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUColorView.h"
#import "UIColor+HexString.h"

@interface TUColorCollectionViewCell : UICollectionViewCell

@property (nonatomic ,strong) UIView *colorView;

@end

@implementation TUColorCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self.contentView addSubview:self.colorView];
        self.colorView.frame = CGRectMake(2.5, 2.5, 25, 25);
        
    }
    return self;
}

- (UIView *)colorView{
    if (!_colorView) {
        UIView *view = [UIView new];
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        view.layer.borderWidth = 1;
        _colorView = view;
    }
    return _colorView;
}


@end


static const int kheight = 48;
static NSString *cellIdentifier = @"cellIdentifier";

@interface TUColorView()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic ,strong) UICollectionView *collectionView;
@property (nonatomic ,strong) NSMutableArray *colorArray;
@end

@implementation TUColorView{
    NSIndexPath *_currentIndexPath;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        
        self.frame = CGRectMake(0, KDeviceHeight-kheight, KDeviceWidth, kheight);
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.collectionView];

        _currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
        _colorArray = [NSMutableArray new];
        [_colorArray addObject:[UIColor whiteColor]];
        [_colorArray addObject:[UIColor colorWithHexString:@"3D97EB"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"6ACF45"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"FACC5D"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"E99441"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"E84C57"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"D60C6A"]];
        [_colorArray addObject:[UIColor colorWithHexString:@"AA02B1"]];
//        for (int i = 0; i < 10; i++) {
//            [UIColor colorWithHexString:@"cfe2fd"];
//            float r = random()%255;
//            float g = random()%255;
//            float b = random()%255;
//            [_colorArray addObject:[UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]];
//        }
        
    }
    return self;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
        //设置布局方向为垂直流布局
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        //设置每个item的大小为100*100

        layout.itemSize = CGSizeMake(30, 30);
        layout.minimumLineSpacing = 12;
//        layout.minimumInteritemSpacing = 12;
        
        //创建collectionView 通过一个布局策略layout来创建
        UICollectionView * collect = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, KDeviceWidth, kheight) collectionViewLayout:layout];
        //代理设置
        collect.backgroundColor = [UIColor clearColor];
        collect.delegate=self;
        collect.dataSource=self;
//        collect.pagingEnabled = YES;
        collect.showsHorizontalScrollIndicator = NO;
        //注册item类型 这里使用系统的类型
        [collect registerClass:[TUColorCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
        
        _collectionView = collect;

        
    }
    return _collectionView;
}


#pragma mark - delegate

//这是正确的方法
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    TUColorCollectionViewCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (_currentIndexPath.row == indexPath.row) {
        cell.colorView.frame = CGRectMake(0, 0, 30, 30);
        cell.colorView.layer.cornerRadius = 15;
    }else{
        cell.colorView.frame = CGRectMake(2.5, 2.5, 25, 25);
        cell.colorView.layer.cornerRadius = 12.5;
    }
   
    cell.colorView.backgroundColor = _colorArray[indexPath.row];
    
    return cell;
}

//返回分区个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

//返回每个分区的item个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _colorArray.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 20, 0, 20);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_currentIndexPath != indexPath) {
        
        _currentIndexPath = indexPath;
        [self.collectionView reloadData];
        
        if ([self.delegate respondsToSelector:@selector(tapColor:)]) {
            [self.delegate tapColor:[_colorArray objectAtIndex:indexPath.row]];
        }
    }
    
}


@end




































