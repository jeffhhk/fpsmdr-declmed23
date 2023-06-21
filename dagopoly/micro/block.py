import inspect
import hashlib
from .dagopoly import Dagopoly, DagopolyBase
import os
from types import LambdaType

import sys as _sys
from keyword import iskeyword as _iskeyword
from operator import itemgetter as _itemgetter

try:
    from _collections import _tuplegetter
except ImportError:
    _tuplegetter = lambda index, doc: property(_itemgetter(index), doc=doc)


class Block(tuple):
    def __iter__(self):
        raise TypeError("Cannot iterate Block.  Did you forget to .get()?")

def recurse_sig(arg):
    if issubclass(arg.__class__, Block):
        return arg.sig()
    if isinstance(arg, list):
        return recurse_sigs(arg)
    if isinstance(arg, tuple):
        return recurse_sigs(arg)
    if isinstance(arg, LambdaType): # Assume any functions are pure and exogenously versioned.
        return "<LambdaType>"               # Buyer beware!
    if not (isinstance(arg, int) or isinstance(arg, str)):
        print("WARNING: unexpected class {} in signature argument: {}".format(arg.__class__.__name__, arg))
    return arg

def recurse_sigs(args):
    return [recurse_sig(arg) for arg in args]

def compute_sig(tags, args):
    s = tags + recurse_sigs(args)
    # if Dagopoly().isDebug():
    #     print("sig: {}".format(s))
    return s

def hash_sig(sig):
    return hashlib.sha1(str(sig).encode('utf-8')).hexdigest()

class CachedBlock(Block):
    def __new__(cls, block):
        self = super().__new__(cls)
        self._block = block
        return self

    def __init__(self, block):
        pass

    def sig(self):
        return self._block.sig()

    def get(self):
        s = self._block.sig()
        h = hash_sig(s)
        rfile = os.path.join("derived", h)
        if not Dagopoly().io().exists(rfile):
            if Dagopoly().isDebug():
                print("populating: {} at {}".format(s, rfile))
            if not Dagopoly().isDryRun():
                Dagopoly().io().write(self._block.get(), rfile)
        else:
            if Dagopoly().isDebug():
                print("remembering: {} at {}".format(s, rfile))
        if Dagopoly().isDryRun():
            return ()
        else:
            return Dagopoly().io().read(rfile)

class CachableBlock(Block):
    def cached(self):
        return CachedBlock(self)

def block(v):
    def decorator(func):
        def _class(typename, field_names):
            typename = _sys.intern(str(typename))

            arg_list = ', '.join(field_names)
            if len(field_names) == 1:
                arg_list += ','
            tuple_new = tuple.__new__

            namespace = {
                '_tuple_new': tuple_new,
                '__builtins__': {},
                '__name__': f'namedtuple_{typename}',
            }
            code = f'lambda _cls, {arg_list}: _tuple_new(_cls, ({arg_list}))'
            __new__ = eval(code, namespace)
            __new__.__name__ = '__new__'
            __new__.__doc__ = f'Create new instance of {typename}({arg_list})'

            def _args(self):
                return [self.__getitem__(i) for i in range(0,self.__len__())]

            def _get(self):
                if Dagopoly().isDebug():
                    print("computing: {}".format(self.sig()))
                args=self._args()
                return func(*args)
            
            def _sig(self):
                return compute_sig([v, typename], self._args())

            def _iter(self):
                raise TypeError("Cannot iterate Block.  Did you forget to .get()?")

            def _cached(self):
                return CachedBlock(self)

            class_namespace = {
                '__doc__': f'{typename}',
                '__slots__': (),
                '_fields': field_names,
                '__new__': __new__,
                '_args': _args,
                'get':_get,
                'sig':_sig,
                '__iter__': _iter,
                'cached':_cached,
            }
            for index, name in enumerate(field_names):
                doc = _sys.intern(f'Alias for field number {index}')
                class_namespace[name] = _tuplegetter(index, doc)

            result = type(typename, (Block,), class_namespace)

            return result

        return _class(func.__name__, inspect.getfullargspec(func).args)
    return decorator
