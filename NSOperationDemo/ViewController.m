//
//  ViewController.m
//  NSOperationDemo
//
//  Created by edianzu on 2018/6/1.
//  Copyright © 2018年 com.zhy.gvgcn. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,assign)__block NSInteger ticketCount;
@property (nonatomic,strong)__block NSLock *lock;
@end

@implementation ViewController

#pragma mark NSInvocationOperation使用步骤
- (void)onlyInvocationOperation {
    
    //1.创建NSInvocationOperation对象
    NSInvocationOperation *invocation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(invocationMethod) object:nil];
    //2.调用start方法 开始执行操作
    [invocation start];
    //   ** 说明：在没有使用NSOperationQueue，在主线程中单独使用子类NSInvocationOperation执行一个操作的情况下，操作时再当前线程中执行的，并没有开启新线程
}

#pragma mark NSBlockOperation使用步骤
- (void)onlyBlockOperation {

    //1.创建NSBlockOperation对象
    NSBlockOperation *blockOpt = [NSBlockOperation blockOperationWithBlock:^{
        
        for (int i = 0 ; i < 2; i ++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"NSBlockOperation1 ----%@",[NSThread currentThread]);
        }
    }];
    
    [blockOpt addExecutionBlock:^{
        for (int i = 0 ; i < 2; i ++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"NSBlockOperation2 ----%@",[NSThread currentThread]);
        }
    }];
    
    [blockOpt addExecutionBlock:^{
        for (int i = 0 ; i < 2; i ++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"NSBlockOperation3 ----%@",[NSThread currentThread]);
        }
    }];
    
    [blockOpt addExecutionBlock:^{
        for (int i = 0 ; i < 2; i ++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"NSBlockOperation4 ----%@",[NSThread currentThread]);
        }
    }];
    
    #warning addExecutionBlock
    //    通过addExecutionBlock可以添加额外的操作。这些操作addExecutionBlock(包括blockOperationWithBlock)可以在不同的线程中同时执行，只有当所有相关的操作已经完成执行时，才视为完成。
    
    //2.调用start开始执行
    [blockOpt start];
    //   ** 说明：在没有使用NSOperationQueue，在主线程中单独使用子类NSBlockOperation执行一个操作的情况下，操作时再当前线程中执行的，并没有开启新线程
    //    一般情况下NSBlockOperation对象可以 封装多个操作。是否开启新线程，取决于操作的个数。如果添加的操作个数多，就会自动开启新线程，当然开启的线程数由系统来决定
}

#pragma mark 创建队列使用步骤：
- (void)operationQuque {
    //1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    //设置成1的话，就是串行队列
    queue.maxConcurrentOperationCount = 1;
    //2.创建操作
    NSInvocationOperation *opt1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(InvocationInQueue1) object:nil];
    
    NSInvocationOperation *opt2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(InvocationInQueue2) object:nil];
    
    NSBlockOperation *blockOpt1 = [NSBlockOperation blockOperationWithBlock:^{
        
        for (int i = 0; i<2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"block1 in queue ----- %@",[NSThread currentThread]);
        }
        
    }];
    
    [blockOpt1 addExecutionBlock:^{
        for (int i = 0; i<2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"block2 in queue ----- %@",[NSThread currentThread]);
        }
    }];
    
    //3.添加操作到队列中
    [queue addOperation:opt1];
    [queue addOperation:opt2];
    [queue addOperation:blockOpt1];
//    说明：使用NSOperation子类创建操作，并使用addOperation：将操作添加到操作队列后能够开启新线程，并发执行
    
    
#warning 可以直接使用addOperationWithBlock将操作添加到队列中
    [queue addOperationWithBlock:^{
        for (int i = 0; i<2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"addOperationWithBlock in queue ----- %@",[NSThread currentThread]);
        }
    }];
    
}

#pragma  mark 操作依赖的使用
- (void)addDependency {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    NSBlockOperation *optA = [NSBlockOperation blockOperationWithBlock:^{
        
        for (int i = 0; i<2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"optA ----- %@",[NSThread currentThread]);
        }
    }];
    
    NSBlockOperation *optB = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i<2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"optB ----- %@",[NSThread currentThread]);
        }
    }];
    
    //需要让A执行完毕后，才执行B ,那么就是B依赖于A
    [optB addDependency:optA];
    
    [queue addOperation:optA];
    [queue addOperation:optB];

}

#pragma mark 线程安全和线程同步
- (void)initTicketQueue {
    
    self.ticketCount = 50;
    self.lock = [[NSLock alloc]init];
    
    NSOperationQueue *queue1 = [[NSOperationQueue alloc]init];
    [queue1 addOperationWithBlock:^{
    
        while (1) {
            
            //在操作数据的时候添加锁
            [self.lock lock];
            
            if (self.ticketCount > 0) {
                self.ticketCount -- ;
                NSLog(@"剩余票数：%ld---窗口号：北京",self.ticketCount);
            }
            [self.lock unlock];
            
            if (self.ticketCount <= 0) {
                NSLog(@"所有火车票已经卖完啦！");
                break;
            }
        }
        
    }];
    
    NSOperationQueue *queue2 = [[NSOperationQueue alloc]init];
    [queue2 addOperationWithBlock:^{
        
        while (1) {
            
            //在操作数据的时候添加锁
            [self.lock lock];
            
            if (self.ticketCount > 0) {
                self.ticketCount -- ;
                NSLog(@"剩余票数：%ld---窗口号：上海",self.ticketCount);
            }
            
            [self.lock unlock];
            if (self.ticketCount <= 0) {
                NSLog(@"所有火车票已经卖完啦！");
                break;
            }
        }
        
    }];
    
    //如果不加线程锁[NSLock]，ticketCount同时可能有两个线程去修改它，造成显示的票数是错乱的
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    **************************NSOperation简介**************************
    
//    NSOperation 是苹果提供给我们的一套多线程解决方案，实际上NSOperation是基于GCD更高一层的封装，完全面向对象，但是比GCD更简单易用，代码可读性更高
    
//    NSOperation好处
//    可添加完成的代码块，在操作完成后执行
//    添加操作之间的依赖关系，方便的控制执行顺序
//    设置操作执行的优先级
//    可以很方便的取消一个操作的执行
//    使用KVO观察对操作执行状态的更改:isExecuteing,isFinished,isCancelled;
    
//    **************************NSOperation使用步骤：**************************
//
//    1.创建操作：先将需要执行的操作封装到一个NSOperation对象中
//         NSOperation是一个抽象类，不能用来封装，我们只有使用它的子类来封装操作
//        （1）：使用子类NSInvocationOperation
//        （2）：使用子类NSBlockOperation
//        （3）：自定义继承自NSOperation的子类，通过实现内部相应的方法来封装操作
//    2.创建队列：创建NSOperationQueue对象
//    3.将操作加入到队列中：将NSOperation对象添加到NSOperationQueue对象中
//    4.系统会自动将NSOperationQueue中的NSoperation取出来，在新线程中执行操作
    
    

    
    
    
//    **************************创建队列使用步骤：**************************
    
    //主队列
//    NSOperationQueue *mainQUeue = [NSOperationQueue mainQueue];
    //凡是添加到主队列中的操作，都会放在主线程中执行
    
    //自定义队列  包含了串行 并行功能
//    NSOperationQueue *myQueue = [[NSOperationQueue alloc]init];
    //添加到自定义队列中的操作，就会自动放到子线程中执行，
//    [self operationQuque];
    
    
    
#warning mark 控制串行执行，并发执行
//    在队列中有一个关键属性：maxConcurrentOperationCount,叫做最大并发操作数，用来控制一个特定队列中可以有多少个操作同时参与并发执行
//    maxConcurrentOperationCount默认情况下时-1；表示不进行限制，可并发执行
//    maxConcurrentOperationCount为1时，队列为串行队列，只能串行执行
//    maxConcurrentOperationCount大于1时，队列为并发队列，这个值不能超过系统限制
    
    
#warning 操作依赖
//    能添加操作之间的依赖关系，跟方便的控制操作之间的执行顺序
    
//    1.-(void) addDependency:(NSOperation *)op 添加依赖 使当前操作依赖于操作op的完成
//    2.-(void) removeDependency:(NSOperation *)op 移除依赖 取消当前操作对操作op的依赖
//    3.@property(readonly,copy)NSArray<NSOperation *>dependencies;当前操作开始执行之前完成执行的所有操作对象数组
    
//    比如：两个操作A和B，需要等A执行完毕后，再执行B，[B addDependency:A]; B依赖于A；
    
//    [self addDependency];
    
    
#warning 优先级
//    NSOperationQueue提供了优先级，queuePriority属性适用于同一操作队列中的操作，不适用于不同操作队列中的操作。默认情况下，所有新创建的操作对象优先级都是NSOperationQuquePriorityNormal
    
#warning 线程安全 若每个线程中对全局变量、静态变量只有读操作，而无写操作，一般来说，这个全局变量是线程安全的；若有多个线程同时执行写操作（更改变量），一般都需要考虑线程同步，否则的话就可能影响线程安全。
    
#warning  线程同步：线程A和线程B一块配合，A执行到一定程度时需要依靠线程B的某个结果，于是停下来，示意B运行；B依言执行，再将结果给A，A再继续操作
    
//    实例：我们模拟火车票售卖的方式，实现 NSOperation 线程安全和解决线程同步问题。
//    场景：总共有50张火车票，有两个售卖火车票的窗口，一个是北京火车票售卖窗口，另一个是上海火车票售卖窗口。两个窗口同时售卖火车票，卖完为止。
    [self initTicketQueue];
    
}

- (void)invocationMethod {
    for (int i = 0; i < 2; i ++) {
        [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
        NSLog(@"invocation ----%@",[NSThread currentThread]);
    }
}


- (void)InvocationInQueue1 {
    for (int i = 0; i < 2; i ++) {
        [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
        NSLog(@"invocation1 in queue ----%@",[NSThread currentThread]);
    }
}

- (void)InvocationInQueue2 {
    for (int i = 0; i < 2; i ++) {
        [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
        NSLog(@"invocation2 in queue ----%@",[NSThread currentThread]);
    }
}


@end
