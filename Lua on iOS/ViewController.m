//
//  ViewController.m
//  Lua on iOS
//

#import "ViewController.h"
#import "LuaManager.h"
#import "Person.h"


// let's prefix `lua_CFunctions` with `l_` as in http://www.lua.org/pil/26.1.html
int l_sum(lua_State *L) {
    // get arguments (`int numberOfArguments = lua_gettop(L)`)
    double x = lua_tonumber(L, 1);
    double y = lua_tonumber(L, 2);

    // compute result
    double result = x + y;

    // return one result
    lua_pushnumber(L, result);
    return 1;
}


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self requestData];
    NSString *pathFile =  [self getDoc];
    NSString *pathForlua = [NSString stringWithFormat:@"%@/script/main.lua",pathFile];
    if ([self fileExistsAtPath:pathForlua  isDirectory:NO]){
        NSString *path = [[NSBundle mainBundle] pathForResource:pathForlua ofType:nil];
        NSString* fileText = [NSString stringWithContentsOfFile:pathForlua encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"%@fileText %@",path,fileText);
    }
    
    // create a manager
    LuaManager *m = [[LuaManager alloc] init];

    // run sth simple
    [m runCodeFromString:@"print(2 + 2)"];

    // maintain state
    [m runCodeFromString:@"x = 0"];
    [m runCodeFromString:@"print(x + 1)"];

    // run file
    NSString *path = [[NSBundle mainBundle] pathForResource:@"foo" ofType:@"lua"];
    [m runCodeFromFileWithPath:path];

    // call objc function from lua
    [m registerFunction:l_sum withName:@"sum"];
    [m runCodeFromString:@"print(sum(1, 2))"];

    // create a person called Alice
    Person *person = [[Person alloc] init];
    person.name = @"Alice";
    NSLog(@"Person's name is %@.", person.name);

    // rename person to Bob
    [m registerFunction:l_set_person_name withName:@"set_person_name"];
    [m callFunctionNamed:@"set_person_name_to_bob" withObject:person];
    NSLog(@"Person's name is %@.", person.name);
}

- (void)requestData {
    
  
    //1. 创建一个网络请求
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/main.lua"];
    
    //2.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //3.获得会话对象
    NSURLSession *session=[NSURLSession sharedSession];
    [[session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"%@",response);
        if(!error){
            NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                 NSString *dirPath = [cachePath stringByAppendingPathComponent:@"script"];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if(![fileManager fileExistsAtPath:dirPath]){
                         
                         [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
                     }else{
                         //删除原文件夹，创建新文件夹
                         [fileManager removeItemAtPath:dirPath error:nil];
                         [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
             
                     }
            NSString *savePath = [dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lua",@"main"]];
                 NSURL *saveURL = [NSURL fileURLWithPath:savePath];
             
                 // 文件移动到cache路径中
                 [[NSFileManager defaultManager] moveItemAtURL:location toURL:saveURL error:nil];
            
        }
        }] resume];

}

- (NSString *)getDoc{
    NSString *homePath = NSHomeDirectory();
        NSLog(@"NSHomeDirectory: %@", homePath);
    // 获取Library中的Cache
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesPath = [paths lastObject];
    NSLog(@"NSCachesDirectory: %@", cachesPath);
    return cachesPath;
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDir {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:path isDirectory:isDir];
    return exist;
}

@end
