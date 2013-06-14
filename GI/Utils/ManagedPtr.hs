{-# LANGUAGE ScopedTypeVariables #-}
module GI.Utils.ManagedPtr
    ( ManagedPtr(..)
    , BoxedObject(..)
    , newObject
    , wrapObject
    , refObject
    , unrefObject
    , newBoxed
    , wrapBoxed
    , copyBoxed
    , freeBoxed
    ) where

import Foreign.Safe
import GI.Utils.BasicTypes (GType)

class ManagedPtr a where
    unsafeManagedPtrGetPtr :: a -> Ptr b
    touchManagedPtr        :: a -> IO ()

class BoxedObject a where
    boxedType :: a -> IO GType -- This should not use the value of its
                               -- argument.

-- Reference counting for constructors
foreign import ccall unsafe "&g_object_unref"
    ptr_to_g_object_unref :: FunPtr (Ptr a -> IO ())

foreign import ccall "g_object_ref" g_object_ref ::
    Ptr a -> IO (Ptr a)

-- Construct a Haskell wrapper for a GObject, making a copy.
newObject :: (ForeignPtr a -> a) -> Ptr b -> IO a
newObject constructor ptr = do
  _ <- g_object_ref $ castPtr ptr
  fPtr <- newForeignPtr ptr_to_g_object_unref $ castPtr ptr
  return $! constructor fPtr

foreign import ccall "g_object_ref_sink" g_object_ref_sink ::
    Ptr a -> IO (Ptr a)

-- Same as makeNewObject, but we take ownership of the object (which
-- is typically floating), so we use g_object_ref_sink.
wrapObject :: (ForeignPtr a -> a) -> Ptr b -> IO a
wrapObject constructor ptr = do
  _ <- g_object_ref_sink $ castPtr ptr
  fPtr <- newForeignPtr ptr_to_g_object_unref $ castPtr ptr
  return $! constructor fPtr

refObject :: (ManagedPtr a) => a -> IO (Ptr b)
refObject obj = do
  let ptr = unsafeManagedPtrGetPtr obj
  _ <- g_object_ref ptr
  touchManagedPtr obj
  return $ castPtr ptr

foreign import ccall "g_object_unref" g_object_unref ::
    Ptr a -> IO ()

unrefObject :: (ManagedPtr a) => a -> IO ()
unrefObject obj = do
  let ptr = unsafeManagedPtrGetPtr obj
  g_object_unref ptr
  touchManagedPtr obj

foreign import ccall unsafe "& boxed_free_helper" boxed_free_helper ::
    FunPtr (Ptr env -> Ptr a -> IO ())

foreign import ccall unsafe "g_boxed_copy" g_boxed_copy ::
    GType -> Ptr a -> IO (Ptr a)

-- Construct a Haskell wrapper for the given boxed object. We make a
-- copy of the object.
newBoxed :: forall a. BoxedObject a => (ForeignPtr a -> a) -> Ptr a -> IO a
newBoxed constructor ptr = do
  gtype <- boxedType (undefined :: a)
  env <- malloc :: IO (Ptr GType)   -- Will be freed by boxed_free_helper
  poke env gtype
  ptr' <- g_boxed_copy gtype ptr
  fPtr <- newForeignPtrEnv boxed_free_helper env ptr'
  return $! constructor fPtr

-- Like makeNewBoxed, but we do not make a copy (we "steal" the passed
-- object, so now it is managed by the Haskell GC).
wrapBoxed :: forall a. BoxedObject a => (ForeignPtr a -> a) -> Ptr a -> IO a
wrapBoxed constructor ptr = do
  gtype <- boxedType (undefined :: a)
  env <- malloc :: IO (Ptr GType)   -- Will be freed by boxed_free_helper
  poke env gtype
  fPtr <- newForeignPtrEnv boxed_free_helper env ptr
  return $! constructor fPtr

-- Make a copy of the given boxed object.
copyBoxed :: forall a b. (BoxedObject a, ManagedPtr a) => a -> IO (Ptr b)
copyBoxed boxed = do
  gtype <- boxedType (undefined :: a)
  let ptr = unsafeManagedPtrGetPtr boxed
  ptr' <- g_boxed_copy gtype ptr
  touchManagedPtr boxed
  return $ castPtr ptr'

foreign import ccall "g_boxed_free" g_boxed_free ::
    GType -> Ptr a -> IO ()

-- Free the memory associated with a boxed object
freeBoxed :: forall a. (BoxedObject a, ManagedPtr a) => a -> IO ()
freeBoxed boxed = do
  gtype <- boxedType (undefined :: a)
  let ptr = unsafeManagedPtrGetPtr boxed
  g_boxed_free gtype ptr
  touchManagedPtr boxed