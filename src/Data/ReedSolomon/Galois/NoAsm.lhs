> module Data.ReedSolomon.Galois.NoAsm (
>       galMulSlice
>     , galMulSliceXor
>     ) where
>
> import Data.Bits (xor)
> import Data.Word (Word8)
>
> import Control.Monad.Primitive (PrimMonad, PrimState)
>
> import Control.Loop (numLoop)
>
> import qualified Data.Vector.Generic as V (unsafeIndex)
> import qualified Data.Vector.Storable as V hiding (unsafeIndex)
> import qualified Data.Vector.Storable.Mutable as MV
>
> import qualified Data.ReedSolomon.Galois.GenTables as GenTables

//+build !amd64 noasm appengine

// Copyright 2015, Klaus Post, see LICENSE for details.

package reedsolomon

func galMulSlice(c byte, in, out []byte) {
	mt := mulTable[c]
	for n, input := range in {
		out[n] = mt[input]
	}
}

> galMulSlice :: PrimMonad m => Word8 -> V.Vector Word8 -> V.MVector (PrimState m) Word8 -> m ()
> galMulSlice c in_ out = do
>     let mt = V.unsafeIndex GenTables.mulTable (fromIntegral c)
>     numLoop 0 (V.length in_ - 1) $ \n -> do
>         let input = V.unsafeIndex in_ n
>         MV.unsafeWrite out n (V.unsafeIndex mt (fromIntegral input))

func galMulSliceXor(c byte, in, out []byte) {
	mt := mulTable[c]
	for n, input := range in {
		out[n] ^= mt[input]
	}
}

> galMulSliceXor :: PrimMonad m => Word8 -> V.Vector Word8 -> V.MVector (PrimState m) Word8 -> m ()
> galMulSliceXor c in_ out = do
>     let mt = V.unsafeIndex GenTables.mulTable (fromIntegral c)
>     numLoop 0 (V.length in_ - 1) $ \n -> do
>         let input = V.unsafeIndex in_ n
>         outn <- MV.unsafeRead out n
>         MV.unsafeWrite out n (outn `xor` V.unsafeIndex mt (fromIntegral input))
