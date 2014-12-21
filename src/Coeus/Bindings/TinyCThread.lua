--[[
	TinyCThread Binding

	A binding to TinyCthread, included in coeus_aux.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")
local tct = Coeus.Bindings.coeus_aux

--Platform-specific typedefs
if (ffi.os == "Windows") then
	C:Get("Coeus.Bindings.Win32_")
	ffi.cdef([[
	typedef int time_t;
	typedef int clock_t;
	typedef int clockid_t;

	typedef struct _tthread_timespec {
		time_t tv_sec;
		long   tv_nsec;
	};

	typedef struct timespec {
		time_t tv_sec;
		long tv_nsec;
	};

	typedef int _tthread_clockid_t;
	int _tthread_clock_gettime(clockid_t clk_id, struct timespec *ts);

	typedef struct {
		CRITICAL_SECTION mHandle;   /* Critical section handle */
		int mAlreadyLocked;         /* TRUE if the mutex is already locked */
		int mRecursive;             /* TRUE if the mutex is recursive */
	} mtx_t;

	typedef struct {
	  HANDLE mEvents[2];                  /* Signal and broadcast event HANDLEs. */
	  unsigned int mWaitersCount;         /* Count of the number of waiters. */
	  CRITICAL_SECTION mWaitersCountLock; /* Serialize access to mWaitersCount. */
	} cnd_t;

	typedef HANDLE thrd_t;
	typedef DWORD tss_t;
	]])
else
	ffi.cdef([[
	typedef pthread_mutex_t mtx_t;
	typedef pthread_cond_t cnd_t;
	typedef pthread_t thrd_t;
	typedef pthread_key_t tss_t;
	]])
end

ffi.cdef([[
/*
Copyright (c) 2012 Marcus Geelnard

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

/** TinyCThread version (major number). */
enum {
	TINYCTHREAD_VERSION_MAJOR = 1,
	TINYCTHREAD_VERSION_MINOR = 1,
	TINYCTHREAD_VERSION = 101,

	TSS_DTRO_ITERATIONS = 0,

	thrd_error = 0,
	thrd_success = 1,
	thrd_timeout = 2,
	thrd_busy = 3,
	thrd_nomem = 4,

	mtx_plain = 1,
	mtx_timed = 2,
	mtx_try = 4,
	mtx_recursive = 8
};

int mtx_init(mtx_t *mtx, int type);
void mtx_destroy(mtx_t *mtx);
int mtx_lock(mtx_t *mtx);
// NOT IMPLEMENTED AS OF 1.1
// int mtx_timedlock(mtx_t *mtx, const struct timespec *ts);
int mtx_trylock(mtx_t *mtx);
int mtx_unlock(mtx_t *mtx);

int cnd_init(cnd_t *cond);
void cnd_destroy(cnd_t *cond);
int cnd_signal(cnd_t *cond);
int cnd_broadcast(cnd_t *cond);
int cnd_wait(cnd_t *cond, mtx_t *mtx);
int cnd_timedwait(cnd_t *cond, mtx_t *mtx, const struct timespec *ts);

typedef int (*thrd_start_t)(void *arg);

int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);
thrd_t thrd_current(void);
// NOT IMPLEMENTED AS OF 1.1
//int thrd_detach(thrd_t thr);
int thrd_equal(thrd_t thr0, thrd_t thr1);
void thrd_exit(int res);
int thrd_join(thrd_t thr, int *res);
int thrd_sleep(const struct timespec *time_point, struct timespec *remaining);
void thrd_yield(void);

typedef void (*tss_dtor_t)(void *val);
int tss_create(tss_t *key, tss_dtor_t dtor);
void tss_delete(tss_t key);
void *tss_get(tss_t key);
int tss_set(tss_t key, void *val);
]])

return tct