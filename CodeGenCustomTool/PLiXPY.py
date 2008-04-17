# python library for plix translations

import sys
import math

debug = 0

# simplify the generated code
class Meta(type):
    inits = []
    def __init__(cls, name, bases, dict):
        # defines "__super" --
        # (copied from http://www.python.org/download/releases/2.2.3/descrintro/)
        # Simplifies translation of "callThis"
        # With this I can generate "__super" whenever C# would generate "base"
        super(Meta, cls).__init__(name, bases, dict)
        setattr(cls, "_%s__super" % name, super(cls))
        cls._function_router['class'] = cls  # needed?
        if hasattr(cls, '_StaticInit'):  #'_' + name):
            Meta.inits.append(cls._StaticInit)  # call all static constructors at load time

    @classmethod
    def do_inits(cls):
        for i in Meta.inits:
            i()

class Object(object):
    """
Use this as the default parent class.
Adding code here so that it doesn't have to be repeated in every generated
class.
"""
    __metaclass__ = Meta
    _function_router = {}
##    def _base(self):
##        def
    def ToString(self):  # not used anymore?
        return self.__class__.__name__
    def __str__(self):
        return self.__class__.__name__
    __repr__ = __str__

# to add additional behaviors to enum object if needed
class enum(Object):
    pass

def names(_function_router):
    """
Generate this decorator in front of all functions, except static funtions
with the same name as the class.
Allow muliple functions/constructors to have the same name.
Execution depends on the number of parameters, not the types of parameters.
"""
    # make sure that it handles
    #   replacement of parent function w/ same number of parameters
    #   execution of parent funtion with different number of parameters
    #   execution of grandparent function when needed
    def decorator(function):
        fname = function.__name__
        fargs = function.func_code.co_argcount - 1
        frouters = _function_router
        # make sure that a function w/ same arg count not already defined
        assert (fname, fargs) not in frouters
        frouters[(fname, fargs)] = function
        if debug: print 'added %s(%d) to router' % (fname, fargs)
        # print repr(klass.__dict__['function_router'])
        def lookup(cls, name):
            "Look up name in cls and its base classes."
            if cls._function_router.has_key(name):
                return cls._function_router[name]
            for base in cls.__bases__:
                try:
                    return lookup(base, name)
                except AttributeError:
                    pass
            raise AttributeError, name
        def router(self, *parms):
            key = (fname, len(parms))  # call this function
            if _function_router.has_key(key):
                function = _function_router[key]
            else:
                cls = _function_router['class']
                function = lookup(cls, key)
            return function(self, *parms)
        # preserve info set on original function
        router.__name__ = function.__name__
        router.__dict__ = function.__dict__
        router.__doc__ = function.__doc__
        return router
    return decorator


# initiall this will just attend to the number of arguments
# it may be possible to be more specific in the future, but need more
# examples of actual use to determine how
# found info on how to test number of arguements at this web page
# http://www.python.org/dev/peps/pep-0318/
    
class _Tester:
    """
>>> ti = _Tester()
>>> ti.test_decorator("Hello there")
Hello there 1
>>> ti.test_decorator("hello more", "two")
hello more 2
"""
    __metaclass__ = Meta
    _function_router = {}  # redirect funtions execution based on number of parameters

    @names(_function_router)
    def test_decorator(self, hello):
        print hello, 1

    @names(_function_router)
    def test_decorator(self, hello, more):
        print hello, 2

### this may be required to make a static event to be read only
###   -- low priority --
### maybe I'll need this - must experiment first
##class staticproperty(object):
##    '''similar to built in property, but static
##
##fget and fset must be class methods? -  ?no, I'll handle that aspect here?
##'''
##
##    def __init__(self, fget=None, fset=None):
##        self.fget = fget
##        self.fset = fset
##
##    def __get__(self, obj):
##        if obj is None:
##            return self
##        if self.fget is None:
##            raise AttributeError, "unreadable attribute"
##        return self.fget(obj)
##
##    def __set__(self, obj, value):
##        if self.fset is None:
##            raise AttributeError, "can't set attribute"
##        self.fset(obj, value)
##

def default(kind):
    # known problems:
    # char is a string of length one in python, not a primitive as in C#
    # decimal is also not a primitive
    # don't know if enum will work properly with the enum class I plan to use
    if kind in ('int', 'long', 'byte', 'sbyte', 'short', 'uint', 'ulong', 'ushort', 'enum'):
        value = 0
    elif kind in ('float', 'double'):
        value = 0.0
    elif kind in ('bool'):
        value = False
    else:
        value = None
    return value

def array(kind, *sizes):
    ''' Create an 'empty' array (perhaps multi dimentional)
    '''

    # this will not work with object types
    #    it would make all of them pointers to the same instance
    #    how to fix? if necessary, use copy??
    def empty(size, value):
        return [ value for x in range(size)]

    # different arrays require different initial values
    # need to complete this list

    value = default(kind)

    # need to make this more general
    if len(sizes) == 1:
        a = sizes[0]
        return empty(a, value) 
    elif len(sizes) == 2:
        a = sizes[0]
        b = sizes[1]
        return [ empty(b, value) for y in range(a)]
    elif len(sizes) == 3:
        a = sizes[0]
        b = sizes[1]
        c = sizes[2]
        return [ [ empty(c, value) for y in range(b) ] for z in range(a) ]
    else:
        return []  # should fail

# Used to implement same named function for arrays
def GetUpperBound(matrix, rank):
    if rank == 0:
        return len(matrix)-1
    elif rank == 1:
        return len(matrix[0])-1
    elif rank == 2:
        return len(matrix[0][0])-1
    else:
        raise ValueError

##def dec(function):
###    def router(*parms):
##    # test_decorator_it_works("hello person")
##    print 'the functions name is: ', function.__name__
##    print 'function __class__: ', repr(function.__class__)
##    print 'function dir: ', dir(function)
##    print 'function func_code dir: ', repr(dir(function.func_code))
##    print 'function func_code.co_argcount: ', repr(function.func_code.co_argcount)
##    return function

# emulate the parts of .NET library interface that are required to execute
# the test suite

# used by string format method
# just handles the very simple cases in my test cases
def _replace(string):
    string = string.replace('{0}', '%s')
    string = string.replace('{1}', '%s')
    string = string.replace('{0:F2}', '%.2F')
    return string

# contents are mostly in alphabetical order
class System:

    class Collections:
        class ArrayList(list):
            def Add(self, parm):
                self.append(parm)

        class DictionaryEntry (object):
            def __init__(self, key, value):
                self.Key = key
                self.Value = value

        class Hashtable(dict):
            def __iter__(self):
                return ( System.Collections.DictionaryEntry(key, value)
                         for key, value in self.iteritems() )

            def Add(self, key, value):
                if key in self:
                    raise KeyError
                else:
                    self[key] = value

            def ContainsKey(self, key):
                return key in self

            @property
            def Keys(self):
                return self.keys()

            def Remove(self, key):
                del self[key]

            @property
            def Values(self):
                return self.values()
        
    class Console(object):
        @staticmethod
        def Write(*parms):
            if len(parms) > 1 and isinstance(parms[0], basestring):
                string = parms[0]
                values = parms[1:]
                string = _replace(string)
                sys.stdout.write(string % values)
            else:
                values = [ str(x) for x in parms ]
                sys.stdout.write(''.join(values))
        @staticmethod
        def WriteLine(*parms):
            System.Console.Write(*parms)
            sys.stdout.write('\n')

    class Delegate(object):
        ''' '+' and '-' behavior for delegates '''
        def __init__(self, obj=None):
            self._list = []
            if obj:
                self._list.append(obj)

        def __call__(self, *parms):
            self.onFire(*parms)

        def onFire(self, *parms):  # my be overriden by Events
            # is this the right way to deal with exceptions?
            try:
                for x in self._list:
                    x(*parms)
            except:
                # pass
                raise

        def __add__(self, delegate):
            response = System.Delegate()
            response._list = self._list + delegate._list
            return response

        def __iadd__(self, delegate):
            self.onAdd(delegate)
            return self

        def onAdd(self, delegate):  # may be overriden by Events accessor
            self._list += delegate._list

        def __sub__(self, delegate):
            response = System.Delegate()
            response._list = self._list[:]
            for x in delegate._list:
                if x in response._list:
                    response._list.reverse()  # remove the last occurance
                    response._list.remove(x)
                    response._list.reverse()
            return response

        def __isub__(self, delegate):
            self.onRemove(delegate)
            return self

        def onRemove(self, delegate):  # may be overriden by Event accessor
            for x in delegate._list:
                if x in self._list:
                    response._list.reverse()  # remove the last occurance
                    self._list.remove(x)
                    response._list.reverse()

        def __len__(self):
            return len(self._list)

        # in .NET an empty delegate is replaced with Null
        # here we retain the delegate (so delegates can be added again
        # but allow comparison with None (python's equivalent to Null)
        def __ne__(self, other):
            if other == None and self._list: return True
            return self is other

        def __eq__(self, other):
            if other == None and not(self._list): return True
            return self is other

        @staticmethod
        def Combine(*parms):
            if len(parms) == 2:
                a, b = parms
                return a + b
            else:  # a list of delegates
                d = System.Delegate()
                for x in parms[0]:
                    d += x
                return d

        @staticmethod
        def Remove(a, b):
            return a - b

        def GetInvocationList(self):  # returns list of delegates, not bare functions
            return [ System.Delegate(x) for x in self._list ]

    EventHandler = Delegate  # they do the same thing

    class double(object):
        @staticmethod
        def Parse(string):
            return float(string)
    float = double # alias

    class EventArgs(object):
        '''EventArgs is the base class for classes containing event data.'''
        pass
    EventArgs.Empty = EventArgs()  # for when no data is passed w/ event

    class Int32(object):
        @staticmethod
        def Parse(string):
            return int(string)
    sbyte = Int32 # alias
    short = Int32
    int = Int32
    long = Int32
    byte = Int32
    ushort = Int32
    uint = Int32
    ulong = Int32

    # must use python 'Exception' or it won't be more general than 'StardardError'
    # but it doesn't have the same attributes
    Exception = Exception  # refer to it as System.Exception?
    ArgumentNullException = StandardError  # not the right exception?
    ArithmeticException = ArithmeticError
    NullReferenceException = StandardError  # not the right exception?

    class Math(object):
        @staticmethod
        def Sqrt(value):
            return math.sqrt(value)

    class String(object):
        @staticmethod
        def Format(*parms):
            if len(parms) > 1 and isinstance(parms[0], basestring):
                string = parms[0]
                values = parms[1:]
                string = _replace(string)
                return string % values
            elif len(parms) == 1:
                return parms[0]
            else:
                return "=== format string not provided ==="
        @staticmethod
        def Concat(*parms):
            return ''.join([ str(x) for x in parms ])
    string = String  # alias
    
### maybe I'll need this - must experiment first
##class event(object):
##    '''prevent instance event from being set to null or replaced by delegate
##'''
##    def __init__(self, event=None):
####        if not isinstance(event, System.Delegate):
####            raise AttributeError, "requires Delegate"
##        self.event = event
##
##    def __get__(self, obj, objtype=None):
##        print "in get **"
####        if obj is None:
####            return self
##        if self.event is None:
##            raise AttributeError, "unreadable event"
##        return self.event
##
##    def __set__(self, obj, value):
##        print "in set **"
####        raise AttributeError, "can't set event"
####        if self.event is None:
####            raise AttributeError, "can't set event"
##        if value == None:
##            self.event._list = []
##        elif isinstance(value, System.Delegate):
##            self.event._list = value._list[:]
##        else:
##            self.event = value # pass
##            # raise AttributeError, "event can only be set to None or Delegate"

# maybe I'll need this - must experiment first
class event(object):
    '''prevent instance event from being set to null or replaced by delegate
'''
    def __init__(self, event=None):
        if debug: print "in init"
##        if not isinstance(event, System.Delegate):
##            raise AttributeError, "requires Delegate"
        self.events = {}
        if isinstance(event, System.Delegate):
            self.events[None] = event
        elif event == None:
            pass
        else:
            raise AttributeError, "event can only be set to None or Delegate"

    def __get__(self, obj, objtype=None):
        if debug: print "in get"
        if obj in self.events:
            return self.events[obj]
        else:
            print "error in get"
            raise AttributeError, "unreadable event"

    def __set__(self, obj, value):
        if debug: print "in set"
        if obj in self.events:
            event = self.events[obj]
            if value == None:
                event._list = []
            elif isinstance(value, System.Delegate):
                event._list = value._list[:]
            else:
                print "error in set"
                raise AttributeError, "event can only be set to None or Delegate"
        else:
            if isinstance(value, System.Delegate):
                self.events[obj] = value
            else:
                print 'value is', repr(value)
                raise AttributeError, "event can only be set to None or Delegate"

class test(object):
    def __init__(self):
        self.e = System.Delegate(self.do)
        self.e += System.Delegate(self.dox)
        pass
    e = event()
    f = event(System.Delegate())

    def do(self):
        self.e = 'asd'
    @staticmethod
    def dox():
        test.f = 'zzz'

# temporary - allows System functions without importing System
import __builtin__
__builtin__.__dict__['System'] = System
# __builtin__.__dict__['double'] = System.double

