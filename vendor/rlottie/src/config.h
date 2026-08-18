/* Generated config.h for vendored rlottie build */

/* Disable dynamic image loader plugin (not needed) */
/* #undef LOTTIE_IMAGE_MODULE_SUPPORT */

/* Enable threading support. Builds for a target without threads define
   LOTTIE_NO_THREADS; every std::thread use sits behind this macro, and
   -U cannot serve because this header defines it during inclusion. */
#ifndef LOTTIE_NO_THREADS
#define LOTTIE_THREAD_SUPPORT
#endif

/* Enable model cache support */
#define LOTTIE_CACHE_SUPPORT
