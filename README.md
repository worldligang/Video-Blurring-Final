Video-Blurring-Final
====================
---

更多iOS技术请关注微信公众账号 iOS开发： iOSDevTip

</br>
本文译自[iOS 7 Blur Effects with GPUImage.](http://www.raywenderlich.com/60968/ios-7-blur-effects-gpuimage)

iOS 7在视觉方面有许多改变，其中非常吸引人的功能之一就是在整个系统中巧妙的使用了模糊效果。许多第三方应用程序已经采用了这样的设计细节，并以各种奇妙的和具有创造性的方式使用它。

本文将通过几种不同的技术来实现iOS 7中的模糊效果，当然，这一切都利用了一个名为[GPUImage](https://github.com/BradLarson/GPUImage)的框架。

GPUImage是由[Brad Larson](www.sunsetlakesoftware.com/blog)创建的，它利用GPU，使在图片和视频上应用不同的效果和滤镜变得非常的容易，同时它还拥有出色的性能，并且它的性能要比苹果内置的相关APIs出色。

注意：本文需要一台物理设备来编译并运行示例程序(在模拟器上无法使用)。同样还需要一个iOS开发者账号。如果你还没有开发者账号的 话，可以来[这里](https://developer.apple.com/)注册一个。注册为开发者之后，会有许多福利哟，例如可以使用物理设备来 开发程序，提前获得苹果的相关测试版程序，以及大量的开发资源。

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/TutorialLogo-500x500.png">

iOS中利用GPUImage实现模糊效果

下面我们先来看看本文的目录结构：

    开始
    为什么要是用模糊效果
        深度引导
        上下文
        关注度
    添加静态的模糊效果
        创建截图Category
        利用断点测试截屏图片
        显示截屏图片
        设置contentsRect
        重置模糊滤镜
        对其背景图片
    实时模糊
    线程中简洁的分支
    一些潜在的实时模糊方案
    一个折中的方法——对视频实时模糊
        利用GPUImage对视频进行模糊处理
    何去何从？

开始

首先先来[这里](https://github.com/worldligang/Video-Blurring.git)下载本文的starter工程，并将其解压出来。

用Xcode打开Video Blurring.xcodeproj，并将工程运行到设备中。此时看到程序的效果如下所示：
<img src="http://cdn1.raywenderlich.com/wp-content/uploads/2013/12/Start-700x394.png">

点击屏幕左上角的菜单(三条横纹)，可以看到界面中出现两个选项：录制视频和播放已有视频。

请注意，现在所有的用户界面都有一个灰色的背景，是不是感觉有点沉闷呢，本文我们就利用iOS 7中的模糊效果来替换掉这些沉闷的灰色背景。
为什么要是用模糊效果

除了外观看起来很棒以外，模糊效果还可以让程序给用户带来3个重要的概念：深度引导、上下文和关注度。
深度引导

在用户界面上，模糊效果可以给用户提供一个深度引导效果，并且有利于用户对程序导航的理解。在之前的iOS版本中的深度引导效果是通过：三维斜面 (three-dimensional bevels)和有关泽的按钮(反映出一个模拟的光源)，而在iOS 7中是通过模糊和视差([parallax](http://en.wikipedia.org/wiki/Parallax))来实现的。

这里说的视差效果，可以很明显的观察出来：在装有iOS 7的设备中，将设备从一侧倾斜至另一侧，会发现设备中的图标在移动(会独立于背景)。这样可以给用户做出一个提示：界面是由不同的层构成的，并且重要的界 面元素是在最前面的——这也涉及到下面将要介绍的一个概念：上下文。

上下文

上下文可以让用户在程序内获得一种轴承的感觉。动画的过度效果就提供了一种非常优秀的上下文，当用户点击一个按钮时，在两个view之间利用动画效 果来切换画面(而不是直接显示一个新的view)，可以让用户知道新的view是从哪里出现的，并且可以让用户很容易知道如何回到上一个view。

模糊效果可以将上一个view当做背景显示出来，尽管上一个view已经失去焦点了，不过可以给用户提供更多的上下文：刚刚是在哪里。通知中心就是一个非常棒的例子：当拉下通知中心时，我们可以在背景中看到原来的view(即使现在正在处于通知中心界面)。

关注度

让界面更加关注于某些选择项上，而移除不需要的内容，让用户可以更加快捷的进行导航。用户可以本能的忽略那些被模糊的界面元素，而将注意力集中到某些界面元素中。

通过本文，你将学到两种模糊类型的实现方法：静态模糊和动态模糊。静态模糊代表着快照的时间点，它并不能反映被模糊界面元素的变化。大多数情况下，使用静态模糊效果就足够了。相反，动态模糊则是对需要模糊的背景做出实时更新。

相信看到具体的效果才是最好的，下面我们就来看看模糊效果的具体实现吧！

添加静态的模糊效果

创建一个静态模糊效果首先是将当前屏幕中的view转换为一幅图片。获得图片之后，只需要对图片做模糊处理就可以了。将view转换为一幅图片(截屏)苹果已经提供了一些非常棒的APIs了，并且在iOS 7中又有了新的方法可以让截屏更加快速。

这些新的方法属于[截屏APIs](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/index.html#//apple_ref/occ/instm/UIView/drawViewHierarchyInRect:afterScreenUpdates:)中的一部分，截屏APIs不仅可以对某个view截屏，还能把整个view层次截屏，如果你希望对某个view截屏，那么可以把view中的按钮、标签、开关等各种view也进行截屏。

此处我们将截屏的逻辑实现到UIView的一个category中。这样一来，我们就可以很方便快捷的将任意的view(以及view中的内容)转换为一个图片——也算是代码的重用吧。

创建截图Category

打开File/New/File...，然后选择iOS/Cocoa Touch/Objective-C category，如下图所示：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2013/12/NewCategory-700x477.png">

将这个category命名为Screenshot，并将它的category选为UIView,如下图所示：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/CategoryInfo-700x477.png">

将下面这个方法声明到UIView+Screenshot.h中：

    -(UIImage *)convertViewToImage; 

接着将如下方法添加到 UIView+Screenshot.m 中：

    -(UIImage *)convertViewToImage 
    { 
        UIGraphicsBeginImageContext(self.bounds.size); 
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES]; 
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext(); 
        UIGraphicsEndImageContext(); 
     
        return image; 
    } 

上面的方法中，首先调用了UIGraphicsBeginImageContext()，最后调用的是UIGraphicsEndImageContext()，这两行代码可以理解为图形上下文的一个事物处理过程。一个上下文可以理解为不同的概念，例如屏幕，或者此处可以理解为一幅图片。这里的两行代码起到一个离屏画布的作用——可以将view绘制上去。

drawViewHierarchyInRect:afterScreenUpdates:方法利用view层次结构并将其绘制到当前的上下文中。

最后，UIGraphicsGetImageFromCurrentImageContext()从图形上下文中获取刚刚生成的UIImage。

现在，我们已经完成了category的实现，接着我们只需要在使用到的地方将其import一下即可。

如下代码所示，将代码添加到DropDownMenuController.m顶部：

    #import "UIView+Screenshot.h" 

同时，将如下方法添加到相同的文件中：

    -(void)updateBlur 
    { 
        UIImage *image = [self.view.superview convertViewToImage]; 
    } 

上面的代码确保是对superview进行截屏，而不仅仅是当前的view。不这样做的话，截屏获得的图片只是menu本身。

利用断点测试截屏图片

为了测试截屏的效果，我们在convertViewToImage调用的下面一行添加一个断点。这样当命中断点时，程序会在断点中暂停执行，这样我们就可以看到截屏的图片，以此确保截屏代码的正确性:

<img src="http://cdn2.raywenderlich.com/wp-content/uploads/2013/12/AddBreakpoint.png">

在测试之前还有一件事情需要做：调用上面这个方法。

找到show方法，并在addToParentViewController下面直接调用一下updateBlur：

    -(void)show { 
        [self addToParentViewController]; 
     
        [self updateBlur]; // Add this line 
     
        CGRect deviceSize = [UIScreen mainScreen].bounds; 
     
        [UIView animateWithDuration:0.25f animations:^(void){ 
            _blurView.frame = CGRectMake(0, 0, deviceSize.size.height, MENUSIZE); 
            _backgroundView.frame = CGRectMake(0, 0, _backgroundView.frame.size.width, MENUSIZE); 
        }]; 
    } 

编译并运行程序，点击菜单按钮，可以看到Xcode在断点出停止了，如下所示：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/BreakpointInfo-700x211.png">


在debugger左下角hand pane中选择image，然后单击快速查找图标按钮，就可以预览刚刚的截屏啦：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/ImagePreview-700x416.png">


如上图所示，正是我们所预期的。
显示截屏图片

将截取到的图片显示到菜单的背景中就是小菜一碟啦。

一般来说我们都会利用UIImageView来显示一幅图片，而由于我们要利用GPUImage来模糊图片，所以需要使用GPUImageView。

在这里的工程中，已经添加好了GPUImage框架，我们只需要将头文件import一下即可。

将下面的代码添加到DropDownMenuController.m顶部：

    #import <GPUImage/GPUImage.h> 

注意：GPUImage被包含在一个框架中，所以在import语句中，需要利用尖括弧，而不是双引号。

此时，有一个_blurView，类型为UIView——是菜单的灰色背景。将UIView修改为GPUImageView，如下所示：

    @implementation DropDownMenuController { 
        GPUImageView *_blurView; 
        UIView *_backgroundView; 
    } 

修改之后，Xcode会报一个warning：大意是你利用UIView进行实例化，而不是预期的GPUImageView。

可以通过下面的方法消除这个警告，在viewDidLad中修改做如下修改：

    _blurView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, deviceSize.size.height, 0)]; 

紧随其后，将如下两行代码添加进去，并移除设置背景色的代码：

    _blurView.clipsToBounds = YES; 
    _blurView.layer.contentsGravity = kCAGravityTop; 

clipToBounds属性设置为YES，把超出_blurView范围的子view隐藏起来，而contentsGravity确保图片出现在image view的顶部。

由于_blurView已经用于背景了，所以此处不需要额外设置了。

接着，我们还需要声明一个用于模糊效果的过滤器。

将如下代码添加到DropDownMenuController.m:文件的@implementation中：

    GPUImageiOSBlurFilter *_blurFilter; 

找到之前添加的断点，右键单击，并选中Delete Breakpoint：

<img src="http://cdn4.raywenderlich.com/wp-content/uploads/2013/12/DeleteBreakpoint.png">


下面是非常重要的一步了——初始化模糊滤镜。将如下代码添加到DropDownMenuController.m中：

    -(void)updateBlur 
    { 
        if(_blurFilter == nil){ 
            _blurFilter = [[GPUImageiOSBlurFilter alloc] init]; 
             _blurFilter.blurRadiusInPixels = 1.0f; 
     
        } 
     
        UIImage *image = [self.view.superview convertViewToImage]; 
    } 

注意：上面将模糊半径设置为一个像素，这里暂时将这个值设置低一点，这样可以确保图片的正确定位，当一切ok之后，再增加模糊半径即可。

下面是时候将图片显示到GPUImageView中了。不过并不是简单的实例化一个UIImage，并将其添加到GPUImageView中。首先需创建一个GPUImagePicture。

将如下代码添加到updateBlur方法的底部：

    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image]; 

至此，我们获得了一个图片，模糊滤镜和iamge view。

接着再将如下代码添加到updateBlur底部：

    [picture addTarget:_blurFilter]; 
    [_blurFilter addTarget:_blurView]; 
     
    [picture processImage]; 

上面这几行代码，就像胶水一样，将所有的事情关联起来。将滤镜当做target添加到图片中，然后将image view当做滤镜的target。

上面代码对图片的处理全程发生在GPU上，也就是说当进行模糊计算和显示时，并不会影响到用户界面。当处理结束时，会把图片显示到image view上面。

编译并运行程序，点击菜单按钮，可以看到如下类似画面：

<img src="http://cdn1.raywenderlich.com/wp-content/uploads/2013/12/HalfImage-700x394.png">


上面的图片看起来是不是有点奇怪？看到的图片被缩放到适配到菜单视图中了。要对此做出修正，我们需要指定图片的哪一部分需要显示在GPUImageView中——也就是处理截屏视图的上半部分。

设置contentsRect

按照如下代码所示修改DropDownMenuController.m文件中的show方法：

    -(void)show 
    { 
        [self addToParentViewController]; 
     
        [self updateBlur]; 
     
        CGRect deviceSize = [UIScreen mainScreen].bounds; 
     
        [UIView animateWithDuration:0.25f animations:^(void){ 
            _blurView.frame = CGRectMake(0.0f, 0.0f, deviceSize.size.height, MENUSIZE); 
            _backgroundView.frame = CGRectMake(0.0f, 0.0f, _backgroundView.frame.size.width, MENUSIZE); 
            _blurView.layer.contentsRect = CGRectMake(0.0f, 0.0f, 1.0f, MENUSIZE / 320.0f); // Add this line! 
        }]; 
    } 

通过指定_blurView.layer.contentsRect来定义一个矩形，在单元坐标空间(unit coordinate space)中，表示只使用layer content的一部分。

编译并运行程序，点击菜单按钮，会看到如下图所示效果：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2013/12/HalfBox-700x394.png">


虽然已经使用了图片的一部分，看起来还是不正确，这是因为它的缩放比例还不适合！此处还缺少对正确内容的缩放。

将下面这行代码添加到show方法中动画block的尾部：

    _blurView.layer.contentsScale = (MENUSIZE / 320.0f) * 2; 

contentsScale属性声明了layer在逻辑坐标空间(以点为单位)和物理坐标空间(以像素为单位)之间的映射关系。更高比例因子表示在渲染layer时，一个点代表着多个像素点。

编译并运行程序，点击菜单按钮，可以看到缩放比例已经正常了：

<img src="http://cdn2.raywenderlich.com/wp-content/uploads/2013/12/FullBlur-700x394.png">


没错——看起来好多了！现在关闭程序，然后重新打开，ou~~发生了什么？如下图所示：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2013/12/HalfBlackBox-700x394.png">


看起来这还是有点问题。如果在对view进行animation之前将contentScale设置回2.0，会解决half bar的问题。

将如下代码添加到DropDownMenuController.m中show方法里面的animation block上面：

    _blurView.layer.contentsScale = 2.0f; 

编译并运行程序，然后点击菜单，接着关闭菜单，再打开菜单，此时菜单开起来如下所示：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/FullBlackBox-700x394.png">


现在半个尺寸的黑色box已经没有问题了——但是现在是全尺寸的黑色box！
重置模糊滤镜

上面问题产生的原因是由于进行了二次模糊计算。解决的方法是移除模糊滤镜中的所有target。如果不这样做的话，之后对滤镜的调用不会输出任何的内容——进而引起黑色box的问题。

按照如下代码更新一下updateBlur方法：

    -(void)updateBlur 
    { 
        if(_blurFilter == nil){ 
            _blurFilter = [[GPUImageiOSBlurFilter alloc] init]; 
            _blurFilter.blurRadiusInPixels = 1.0f; 
        } 
     
        UIImage *image = [self.view.superview convertViewToImage]; 
     
        GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image]; 
        [picture addTarget:_blurFilter]; 
        [_blurFilter addTarget:_blurView]; 
     
        [picture processImageWithCompletionHandler:^{ 
            [_blurFilter removeAllTargets]; 
        }]; 
    } 

上面的代码用processImageWithCompletionHandler:替换了processImage方法。这个新的方法有一个completion block，当image 处理结束时，会运行这个block。一旦image处理结束，我们就可以安全的将滤镜中的target全部移除。

编译并运行程序，点击菜单，检查一下黑色box问题是不是已经解决掉了：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2013/12/FinalGrayButton-700x394.png">


多次打开和关闭菜单，确保之前的那个bug已经解决掉啦！

现在仔细观察一下打开菜单的模糊效果——有些东西看起来不正确。为了更加明显的观察到问题，我们减慢动画的时间，让其慢慢的移动。

在show方法中，将animation bloc的持续时间修改为10.0f。

编译并运行程序，点击菜单，然后观察一下菜单出场的慢动作：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/MisalignedBlur-700x394.png">


恩，现在可能你已经发现问题了。被模糊的图片从顶部往下滑动——而我们的本意是希望模糊效果从上往下滑(并不是图片本身)。
对其背景图片

此处我们需要对静态模糊效果使用一些技巧。当出现菜单时，我们需要利用背景来将模糊效果对其。所以在这里我们不是对image view做移动处理，而是需要对image view做扩展处理，从0开始扩展至image view的全尺寸。这样就可以确保菜单打开时，图片依然保留在原位。

在show方法中，我们已经将菜单打开至全尺寸了，所以现在只需要将contentRect的高度设置为0即可(当image view首次创建并隐藏的时候)。

将下面的代码添加至DropDownMenuController.m文件的viewDidLoad方法中——在_blurView初始化的下方：

    _blurView.layer.contentsRect = CGRectMake(0.0f, 0.0f, 1.0f, 0.0f); 

同时，在相同的一个文件中，将下面的代码添加到animation block的尾部：

    _blurView.layer.contentsRect = CGRectMake(0.0f, 0.0f, 1.0f, 0.0f); 

contentRect属性是可以动画方式设置的。因此在动画期间会rect会自动的插补上。

编译并运行程序。可以看到，问题已经解决：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2013/12/HalfView.png">


这样看起来自然多了。现在我们已经有一个具有模糊背景的滑动菜单了。

现在是时候把动画所需时间调整一下了（为了更好的效果，其实之前设置的值是为了测试所用）：设置为0.25秒，接着在updateBlur方法中将_blurFilter.blurRadiusInPixels设置为4.0f。

编译并运行程序，多次打开菜单，看看效果如何：

<img src="http://cdn1.raywenderlich.com/wp-content/uploads/2013/12/FinalBlur-700x394.png">


实时模糊

实时模糊涉及到的技术具有一定的难度，有些难点需要解决才行。为了有效的进行实时模糊，我们需要不停(每秒60帧)的截屏、模糊计算和显示。使用GPUImage每秒中处理60张图片(模糊并显示图片)一点问题都没有。

真正棘手的问题是什么呢？如何实时的截取屏幕图片，信不信由你！

由于截取的屏幕是主用户界面，所有必须使用CPU的主线程来截屏，并将其转换为一幅图片。

提醒：如果事物每秒钟的变化速度在46帧以上，那么人眼就无法识别出来了。这对于开发者来说也是一种解脱——现代处理器在各帧之间可以完成更多的大量工作。
线程中简洁的分支

当运行程序时，会执行大量的指令列表。每一个指令列表都运行在各自的线程中，而我们又可以在多个线程中并发运行各自的指令列表。一个程序在主线程中 开始运行，然后会根据需要，创建新的线程，并在后台执行线程。如果之前你并没有管理过多线程，你可能在写程序的时候总是在主线程中执行指令。

主线程主要处理与用户的交互，以及界面的更新。确保主线程的响应时间是非常关键的。如果在主线程上做了太多的任务，你会明显的感觉到主界面响应迟钝。

如果你曾经使用过Twitter货Facebook，并滚动操作过它里面的内容，你可能已经感觉到后台线程在执行操作了——在滚动的过程中，并不是所有的个人图片立即显示出来，滚动过程中，程序会启动后台线程来获取图片，当图片获取成功之后，再显示到屏幕中。

如果不使用后台线程，那么table view的滚动过程中，如果在主线程上去获取个人图片，会感觉到table view被冻结住了。由于图片的获取需要一些时间，所以最好将这样耗时的操作让后台线程来做，这样就能对用户界面做平滑的操作和响应了。

那么对本文的程序有什么影响呢？之间介绍了，UIView的截屏APIs操作必须在主线程中运行。这就意味着每次截屏时，整个用户界面都会被冻结中。

对于静态模糊效果时，由于这个截屏操作很快，你不会感觉到界面的冻结。并且只需要截屏一次。然而在实时模糊效果中需要每秒中截屏60次。如果在主线程中做这样频繁的截屏操作，那么animation和transition会变得非常的迟钝。

更糟糕的时，如果用户界面复杂度增加，那么在截屏过程中就需要消耗更多的时间，那么就会导致整个程序无法使用了！

那么怎么办呢！
一些潜在的实时模糊方案

这里有一个关于实时模糊方案：源代码开源的[live blur libraries](https://github.com/nicklockwood/FXBlurView)，它通过降低截屏的速度来实现实时模糊效果，并不是使用每秒截屏60次，可能是20、30或者40次。即使看起来没有多大区别，但是你的眼睛还是能发现一定的迟钝——模糊效果并没有跟程序的其它部分同步起来——这样一来，界面看起会没有模糊效果更加的糟糕。

实际上苹果在它们自己的一些程序中处理实时模糊并不存在类似的问题——但是苹果并没有公开相关的API。在iOS 7中UIView的截屏方法，相比于旧方法，性能有了很大的提升，但还是不能满足实时模糊的需求。

一些开发者利用UIToolbar的模糊效果来做一些不好的操作。没错，这是有效果的，但是强烈建议不要在程序中使用它们。虽然这不是私有API，但是这并不算是一种可行的方法，苹果也可能会reject你的程序。也就是说在，在之后的iOS 7版本中，并不能保证还能正常使用。

苹果可以在任何时候对UIToolBar做出修改，或许你的程序就有问题了。在iOS 7.0.3更新中，苹果的修改已经影响到UIToolbar和UINavigationBar了，有些开发者也因此报告出利用相关模糊效果已经失效了！所以最好不要陷入这样潜在的陷阱里面！
一个折中的方法——对视频实时模糊

OK，此时你可能在想，要想在程序中做到实时模糊是不可能的了。那么还有什么方法可以突破限制，做到实时模糊效果呢？

在许多场景中，静态模糊是可以接受的。上一节中，我们对view做适当的修改，让用户看起来是对背景图做的实际模糊处理。当然，这对于静止不动的背景是合适的，并且还可以在模糊背景上实现一些不错的效果。

我们可以做一些实验，看看能不能找到一些效果来实现之前无法做到的实时模糊效果呢？

有一个方法可以试试：对实时视频做模糊处理，虽然截屏是一个非常大的瓶颈，但是GPUImage非常的强大，它能够对视频进行模糊(无论是来自摄像头的视频或者已经录制好的视频，都没问题)。

利用GPUImage对视频进行模糊处理

利用GPUImage对视频的模糊处理与图片的模糊处理类似。针对图片，我们实例化一个GPUImagePicture，然后将其发送给GPUImageiOSBlurFilter，接着再将其发送给GPUImageView。

类似的方法，对于视频，我们使用GPUImageVideoCamera或GPUImageMovie，将后将其发送给GPUImageiOSBlurFilter，接着再将其发送给一个GPUImageView。GPUImageVideoCamera用于设备中的实时摄像头，而GPUImageMovie用于已经录制好的视频。

在我们的starter工程中，已经实例化并配置好了GPUImageVideoCamera。现在的任务是将播放和录制按钮的灰色背景替换为视频的实时滤镜效果。

首先是将此处提供的灰色背景实例UIView替换为GPUImageView。完成之后，我们需要调整每个view的contentRect(基于view的frame)。

这听起来对每个view都需要做大量的工作。为了让任务变得简单，我们创建一个GPUImageView的子类，并把自定义的代码放进去，以便重用。

打开File/New/File…，然后选择iOS/Cocoa Touch/Objective-C class，如下所示：

<img src="http://cdn3.raywenderlich.com/wp-content/uploads/2013/12/NewClass.png">

将类命名为BlurView，继承自GPUImageView，如下图所示：

<img src="http://cdn5.raywenderlich.com/wp-content/uploads/2014/01/Screen-Shot-2014-01-27-at-21.20.01-700x474.png">


打开ViewController.m文件，将下面的import添加到文件顶部：

    #import "BlurView.h" 

还是在ViewController.m中，在@implementation中找到_recordView和_controlView的声明，将其修改为BlurView类型，如下所示：

    BlurView *_recordView; //Update this! 
    UIButton *_recordButton; 
    BOOL _recording; 
     
    BlurView *_controlView; //Update this too! 
    UIButton *_controlButton; 
    BOOL _playing; 

然后按照如下代码修改viewDidLoad方法：

    _recordView = [[BlurView alloc] initWithFrame: 
                    CGRectMake(self.view.frame.size.height/2 - 50, 250, 110, 60)]; //Update this! 
    //_recordView.backgroundColor = [UIColor grayColor]; //Delete this! 
     
    _recordButton = [UIButton buttonWithType:UIButtonTypeCustom]; 
    _recordButton.frame = CGRectMake(5, 5, 100, 50); 
    [_recordButton setTitle:@"Record" forState:UIControlStateNormal]; 
    [_recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal]; 
    [_recordButton setImage:[UIImage imageNamed:@"RecordDot.png"] forState:UIControlStateNormal] ; 
    [_recordButton addTarget:self 
                      action:@selector(recordVideo) 
            forControlEvents:UIControlEventTouchUpInside]; 
     
    [_recordView addSubview:_recordButton]; 
    _recording = NO; 
     
    _recordView.hidden = YES; 
    [self.view addSubview:_recordView]; 
     
     
    _controlView = [[BlurView alloc] initWithFrame: 
                     CGRectMake(self.view.frame.size.height/2 - 40, 230, 80, 80)]; //Update this! 
    //_controlView.backgroundColor = [UIColor grayColor]; //Delete this! 

接着，需要创建模糊图片，将其显示到上面构建的image view中。回到@implementation中，将下面的两个声明添加进去：

    GPUImageiOSBlurFilter *_blurFilter; 
    GPUImageBuffer *_videoBuffer; 

现在你已经知道GPUImageiOSBlurFilter的作用了，那么GPUImageBuffer的作用是什么呢？它的任务是获取视频的输出，并获取每一帧，这样我们就可以方便的对其做模糊处理。一个额外的好处就是它可以提升程序的性能！

一般来说，视频输出的内容会通过模糊滤镜处理，然后发送到背景视图中(被显示出来)。不过，在这里使用buffer的话，发送到buffer的视频输出内容，会被分为背景视图和模糊滤镜。这样可以对视频的输出显示做到平滑处理。

将下面的代码添加到viewDidLoad方法的顶部(在super调用的后面)：

    _blurFilter = [[GPUImageiOSBlurFilter alloc] init]; 
     
    _videoBuffer = [[GPUImageBuffer alloc] init]; 
    [_videoBuffer setBufferSize:1]; 

还是在同一个文件中，将如下高亮显示的语句添加到useLiveCamera方法中：

    -(void)useLiveCamera 
    { 
        if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) { 
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No camera detected" 
                                                            message:@"The current device has no camera" 
                                                           delegate:self 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil]; 
            [alert show]; 
            return; 
        } 
     
        _liveVideo = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 
                                                         cameraPosition:AVCaptureDevicePositionBack]; 
        _liveVideo.outputImageOrientation = UIInterfaceOrientationLandscapeLeft; 
     
        [_liveVideo addTarget:_videoBuffer];           //Update this 
        [_videoBuffer addTarget:_backgroundImageView]; //Add this 
        [_videoBuffer addTarget:_blurFilter];          //And this 
        [_blurFilter addTarget:_recordView];           //And finally this 
     
        [_liveVideo startCameraCapture]; 
     
        _recordView.hidden = NO; 
        _controlView.hidden = YES; 
    } 

上面的模糊背景是用于录制按钮的。对于播放按钮也要做类似的处理。

将下面的代码添加到loadVideoWithURL:方法中(在_recordedVideo.playAtActualSpeed = YES;之后)：

    [_recordedVideo addTarget:_videoBuffer]; 
    [_videoBuffer addTarget:_backgroundImageView]; 
    [_videoBuffer addTarget:_blurFilter]; 
    [_blurFilter addTarget:_controlView]; 

编译并运行程序，打开录制操作，看看情况如何：

<img src="http://cdn2.raywenderlich.com/wp-content/uploads/2013/12/FullImageButton.png">


好消息是看起来基本正常！坏消息是整个屏幕被缩放到录制按钮中去了。这个问题跟之前遇到的类似。我们需要给BlurView这是适当的contentRect。

打开BlurView.m，用下面的代码替换掉initWithFrame:方法：

    - (id)initWithFrame:(CGRect)frame 
    { 
        self = [super initWithFrame:frame]; 
        if (self) { 
            CGRect deviceSize = [UIScreen mainScreen].bounds; 
            self.layer.contentsRect = CGRectMake(frame.origin.x/deviceSize.size.height, 
                                                 frame.origin.y/deviceSize.size.width, 
                                                 frame.size.width/deviceSize.size.height, 
                                                 frame.size.height/deviceSize.size.width); 
            self.fillMode = kGPUImageFillModeStretch; 
        } 
        return self; 
    } 

contentRect的每个参数必须在0.0f和1.0f之间。在这里只需要利用view的位置除以屏幕的size，得到的值即可。

编译并运行程序，看看效果如何：

<img src="http://cdn2.raywenderlich.com/wp-content/uploads/2013/12/FinishedBlur.png">


恭喜！至此已经完成了静态模糊和实时视频模糊的实现。现在你已经完全可以在程序中添加iOS 7的模糊效果啦！
何去何从？

可以在这里下载到完整的工程。

本文不仅指导你在程序中使用iOS 7的模糊效果，还介绍了如何使用GPUImage框架，这个框架也是我非常希望你能看到的东西。重要的是，本文指出了为什么要使用模糊，什么时候使用模糊效果是合适的，这在iOS 7的新设计语言中是一个关键的概念。当然也希望在未来的版本中，苹果能够将相关APIs提供给开发者使用，不过在那之前，GPUImage是一个不错的替代品。
