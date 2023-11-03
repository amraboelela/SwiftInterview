# Senior iOS Developer

## General questions:


### What is the difference between a struct and a class in Swift?

A struct is a value type, while a class is a reference type. This means that when you copy a struct, you create a new copy of the struct's data. When you copy a class, you create a new reference to the class's data.

Structs are typically used to represent small, immutable data structures, such as points, sizes, and rectangles. Classes are typically used to represent larger, mutable data structures, such as view controllers and models.

### What is the difference between a strong reference, a weak reference, and an unowned reference?

A strong reference is a reference that keeps the object it points to alive. A weak reference is a reference that does not keep the object it points to alive. An unowned reference is a similar to a weak reference, but it does not automatically become nil if the object it points to is deallocated.

Strong references are typically used when you need to ensure that an object remains alive until you are finished with it. Weak references are typically used when you do not want to prevent an object from being deallocated, but you still need to be able to access it if it is still alive. Unowned references are typically used when you know that the object you are pointing to will not be deallocated before you are finished with it.

### What is the difference between a delegate and a notification?

A delegate is a protocol that allows you to decouple two objects so that they can communicate with each other without having to know about each other's internal implementation. A notification is a broadcast message that can be sent to any object that has subscribed to it.

Delegates are typically used to implement one-to-one communication between two objects. Notifications are typically used to implement one-to-many or many-to-many communication between objects.

### What is the Model-View-Controller (MVC) design pattern and how do you implement it in your iOS apps?

The Model-View-Controller (MVC) design pattern is a software design pattern that separates the user interface, data, and application logic of an application into three separate components: models, views, and controllers.

Models represent the data of the application. Views represent the user interface of the application. Controllers handle the interaction between the models and the views.

In iOS apps, you can implement the MVC design pattern by using the following classes:

* Models: Use `NSObject` subclasses to represent your models.
* Views: Use `UIView` subclasses to represent your views.
* Controllers: Use `UIViewController` subclasses to represent your controllers.

### What is Grand Central Dispatch (GCD) and how do you use it to manage concurrency in your iOS apps?

Grand Central Dispatch (GCD) is a low-level concurrency framework that allows you to manage the execution of tasks on multiple threads. GCD provides a number of features that make it easy to write concurrent code, such as queues, work groups, and semaphores.

In iOS apps, you can use GCD to manage concurrency by creating queues and assigning tasks to those queues. GCD will then manage the execution of those tasks on multiple threads.

### What is unit testing and how do you use it to test your iOS apps?

Unit testing is a software testing method that tests individual units of code, such as functions, classes, and modules. Unit tests are typically written using a unit testing framework, such as XCTest.

To unit test your iOS apps, you can create unit tests for your models, views, and controllers. You can then run your unit tests in Xcode to ensure that your code is working as expected.

### What is continuous integration and continuous delivery (CI/CD) and how do you use it to automate the development and deployment of your iOS apps?

Continuous integration and continuous delivery (CI/CD) is a set of practices that automates the software development and delivery process. CI/CD helps to ensure that your code is always in a deployable state and that new features can be deployed to production quickly and reliably.

To use CI/CD to automate the development and deployment of your iOS apps, you can use a CI/CD service, such as GitHub Actions or CircleCI. These services allow you to create CI/CD pipelines that can be triggered when you push changes to your code repository. The CI/CD pipeline can then run your unit tests, build your app, and deploy your app to production.

### What is your experience with using version control systems like Git and how do you use them to manage your code?

Git is a distributed version control system that allows you to track changes to your code and collaborate with other developers. Git is widely used in the software development industry
