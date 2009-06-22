// Release an ivar and set to nil.
// Source: http://zathras.de/angelweb/blog-defensive-coding-in-objective-c.htm
#define DESTROY(obj) do { [obj release]; obj = nil; } while(0)
