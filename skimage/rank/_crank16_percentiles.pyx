#cython: cdivision=True
#cython: boundscheck=False
#cython: nonecheck=False
#cython: wraparound=False

import numpy as np
cimport numpy as np

# import main loop
from _core16p cimport _core16p,int_min,int_max

# -----------------------------------------------------------------
# kernels uint16 (SOFT version using percentiles)
# -----------------------------------------------------------------

cdef inline np.uint16_t kernel_autolevel(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,imin,imax,sum,delta

    if pop:
        sum = 0
        p1 = 1.0-p1
        for i in range(maxbin):
            sum += histo[i]
            if sum>p0*pop:
                imin = i
                break
        sum = 0
        for i in range(maxbin-1,-1,-1):
            sum += histo[i]
            if sum>p1*pop:
                imax = i
                break

        delta = imax-imin
        if delta>0:
            return <np.uint16_t>(255*(int_min(int_max(imin,g),imax)-imin)/delta)
        else:
            return <np.uint16_t>(imax-imin)
    else:
        return <np.uint16_t>(0)


cdef inline np.uint16_t kernel_gradient(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,imin,imax,sum,delta

    if pop:
        sum = 0
        p1 = 1.0-p1
        for i in range(maxbin):
            sum += histo[i]
            if sum>=p0*pop:
                imin = i
                break
        sum = 0
        for i in range((maxbin-1),-1,-1):
            sum += histo[i]
            if sum>=p1*pop:
                imax = i
                break

        return <np.uint16_t>(imax-imin)
    else:
        return <np.uint16_t>(0)


cdef inline np.uint16_t kernel_mean(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,sum,mean,n

    if pop:
        sum = 0
        mean = 0
        n = 0
        for i in range(maxbin):
            sum += histo[i]
            if (sum>=p0*pop) and (sum<=p1*pop):
                n += histo[i]
                mean += histo[i]*i

        if n>0:
            return <np.uint16_t>(1.0*mean/n)
        else:
            return <np.uint16_t>(0)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_mean_substraction(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,sum,mean,n

    if pop:
        sum = 0
        mean = 0
        n = 0
        for i in range(maxbin):
            sum += histo[i]
            if (sum>=p0*pop) and (sum<=p1*pop):
                n += histo[i]
                mean += histo[i]*i
        if n>0:
            return <np.uint16_t>((g-(mean/n))*.5+midbin)
        else:
            return <np.uint16_t>(0)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_morph_contr_enh(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,imin,imax,sum,delta

    if pop:
        sum = 0
        p1 = 1.0-p1
        for i in range(maxbin):
            sum += histo[i]
            if sum>p0*pop:
                imin = i
                break
        sum = 0
        for i in range((maxbin-1),-1,-1):
            sum += histo[i]
            if sum>p1*pop:
                imax = i
                break
        if g>imax:
            return <np.uint16_t>imax
        if g<imin:
            return <np.uint16_t>imin
        if imax-g < g-imin:
            return <np.uint16_t>imax
        else:
            return <np.uint16_t>imin
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_percentile(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i
    cdef float sum = 0.

    if pop:
        for i in range(maxbin):
            sum += histo[i]
            if sum>=p0*pop:
                break

        return <np.uint16_t>(i)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_pop(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i,sum,n

    if pop:
        sum = 0
        n = 0
        for i in range(maxbin):
            sum += histo[i]
            if (sum>=p0*pop) and (sum<=p1*pop):
                n += histo[i]
        return <np.uint16_t>(n)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_threshold(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin, float p0, float p1):
    cdef int i
    cdef float sum = 0.

    if pop:
        for i in range(maxbin):
            sum += histo[i]
            if sum>=p0*pop:
                break

        return <np.uint16_t>((maxbin-1)*(g>=i))
    else:
        return <np.uint16_t>(0)

# -----------------------------------------------------------------
# python wrappers
# -----------------------------------------------------------------
def autolevel(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """bottom hat
    """
    return _core16p(kernel_autolevel,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)


def gradient(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return p0,p1 percentile gradient
    """
    return _core16p(kernel_gradient,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)

def mean(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return mean between [p0 and p1] percentiles
    """
    return _core16p(kernel_mean,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)

def mean_substraction(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return original - mean between [p0 and p1] percentiles *.5 +127
    """
    return _core16p(kernel_mean_substraction,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)

def morph_contr_enh(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """reforce contrast using percentiles
    """
    return _core16p(kernel_morph_contr_enh,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)


def percentile(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return p0 percentile
    """
    return _core16p(kernel_percentile,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)


def pop(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return nb of pixels between [p0 and p1]
    """
    return _core16p(kernel_pop,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)

def threshold(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8, float p0=0., float p1=0.):
    """return (maxbin-1) if g > percentile p0
    """
    return _core16p(kernel_threshold,image,selem,mask,out,shift_x,shift_y,bitdepth,p0,p1)
