//
//  GLSLView.m
//  GLSL变换三角形
//
//  Created by 彭文喜 on 2020/8/1.
//  Copyright © 2020 彭文喜. All rights reserved.
//

#import "GLSLView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES3/gl.h>

@interface GLSLView()

@property(nonatomic,strong)CAEAGLLayer *mEagLayer;
@property(nonatomic,strong)EAGLContext *mContext;
@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myProgram;
@property(nonatomic,assign)GLuint myVertices;

@end

@implementation GLSLView
{
    float xAngle;
    float yAngle;
    float zAngle;
    
    BOOL bx;
    BOOL by;
    BOOL bz;
    
    NSTimer *myTimer;
}


-(void)layoutSubviews
{
    //1、设置图层
    [self setupLayer];
    
    //2、设置上下文
    [self setupContext];
    
    //3、清空缓存区
    [self deleteBuffer];
    
    //4、设置render，frame
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render];

}
//6、绘制
-(void)render{
    //1、清屏颜色
    glClearColor(0.5, 0.7, 0.9, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen]scale];
    
    //2、设置视口
    glViewport(self.frame.origin.x*scale, self.frame.origin.y, self.frame.size.width*scale, self.frame.size.height*scale);
    
    //3、获取顶点着色器、片源着色器
    NSString *vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"glsl"];
    
    //4、判断self.myProgram是否存在，
    if(self.myProgram){
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    //5、加载程序到myProgram中来
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    //6、链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    //7、获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error:%@", messageString);
        
        return ;
    }else {
        glUseProgram(self.myProgram);
    }
    
    //8、创建顶点数组&索引数组
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, 1.0f,1.0f,//左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, 0.0f,1.0f,//右上1
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, 0.0f,0.0f,//左下2
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, 1.0f,1.0f,//右下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, 0.0f,1.0f//顶点4
    };
    
    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //(3)判断顶点缓冲区是否为空，如果为空则申请一个缓冲区标识符
    if(self.myVertices == 0){
        glGenBuffers(1, &_myVertices);
    }
    
    //9、处理顶点数据
    
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //打开position
    glEnableVertexAttribArray(position);
    
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);
    
    
    //10、处理顶点颜色值
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    
    glEnableVertexAttribArray(positionColor);
    
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL +3);
    
    //处理纹理数据
    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    
    glEnableVertexAttribArray(textCoor);
    
    
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL+6);
    
    [self setupTexture:@"fengjing.jpg"];
    
    //设置纹理采样器
    glUniform1i(glGetUniformLocation(self.myProgram, "textCoordinate"), 0);
    
    //11、找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    
    //12、创建4*4投影矩阵
    KSMatrix4 _projectionMatrix;
    
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width/height;
    
    ksPerspective(&_projectionMatrix, 30, aspect, 5.0, 20.0);
    
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    
    //13、创建一个4*4矩阵
    KSMatrix4 _modelViewMatrix;
    //获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //平移z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    //创建4*4矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
    //设置为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    //旋转
    ksRotate(&_rotationMatrix, xAngle, 1.0, 0.0, 0.0);
    ksRotate(&_rotationMatrix, yAngle, 0.0, 1.0, 0.0);
    ksRotate(&_rotationMatrix, zAngle, 0.0, 0.0, 1.0);
    //矩阵相乘
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    //将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
    
    //开启正背面剔除
    glEnable(GL_CULL_FACE);

    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    //要求本地窗口系统显示OpenGL ES渲染<目标>
    [self.mContext presentRenderbuffer:GL_RENDERBUFFER];
}

//从图片中加载纹理
-(GLuint)setupTexture:(NSString *)fileName{
    //1、将UIImage转换成CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;

    //判断图片是否获取成功
    if(!spriteImage){
        NSLog(@"图片加载失败");
        exit(1);
    }

    //2、读取图片大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);

    //3、获取图片字节数 宽*高*4（RGBA）

    GLubyte *spriteDate = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));


    //4、创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteDate, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);


    //5、在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);

    //6、使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //翻转
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7、画完图就释放上下文
    CGContextRelease(spriteContext);

    //8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);

    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float fw = width,fh = height;
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteDate);

    //11、释放spriteDate
    free(spriteDate);

    return 0;
}


//5、设置FrameBuffer
-(void)setupFrameBuffer{
    //1、定义一个缓存区
    GLuint buffer;
    //2、申请缓冲区标志
    glGenFramebuffers(1, &buffer);
    //3、赋值
    self.myColorFrameBuffer = buffer;
    //4、设置当前的frameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //5、将myColorFrameBuffer配置到GL_COLOR_ATTACHMENT0附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//4、设置renderbuffer
-(void)setupRenderBuffer{
    //1、定义一个缓冲区
    GLuint buffer;
    //2、申请一个缓冲区标志
    glGenRenderbuffers(1, &buffer);
    //3、赋值
    self.myColorRenderBuffer = buffer;
    //4、将标示符绑定
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.mEagLayer];
}

//3、删除缓冲区
-(void)deleteBuffer{
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;
}

//2、设置上下文
-(void)setupContext{
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if(!context){
        NSLog(@"创建失败");
        return;
    }
    if(![EAGLContext setCurrentContext:context]){
        NSLog(@"设置失败");
        return;
    }
    self.mContext = context;
}

//1、设置图层
-(void)setupLayer{
    self.mEagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    self.mEagLayer.opaque = YES;
    self.mEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}


+(Class)layerClass{
    return [CAEAGLLayer class];
}

-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag{
    //创建两个临时变量
    GLuint verShader,fragShader;
    //创建一个program
    GLuint program = glCreateProgram();
    
    //编译文件
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;

}

//链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建一个shader
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上
    glShaderSource(*shader, 1, &source, NULL);
    
    //将着色器源代码编译成目标代码
    glCompileShader(*shader);
}


- (IBAction)xClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bx = !bx;
}
- (IBAction)yClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    by = !by;
}
- (IBAction)zClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bz = !bz;
}

-(void)reDegree{
    xAngle +=bx * 5;
    yAngle +=by * 5;
    zAngle +=bz * 5;
    //重新渲染
    
    [self render];
}

@end
