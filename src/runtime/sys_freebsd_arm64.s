// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// System calls and other sys.stuff for arm64, FreeBSD
// /usr/src/sys/kern/syscalls.master for syscall numbers.
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

#define AT_FDCWD -100

#define CLOCK_REALTIME 0
#define CLOCK_MONOTONIC 1

#define SYS_exit 1
#define SYS_read 3
#define SYS_write 4
#define SYS_close 6
#define SYS_getpid 20
#define SYS_kill 37
#define SYS_sigaltstack 53
#define SYS_munmap 73
#define SYS_madvise 75
#define SYS_setitimer 83
#define SYS_fcntl 92
#define SYS___sysctl 202
#define SYS_nanosleep 240
#define SYS_clock_gettime 232
#define SYS_sched_yield 331
#define SYS_sigprocmask 340
#define SYS_kqueue 362
#define SYS_kevent 363
#define SYS_sigaction 416
#define SYS_thr_exit 431
#define SYS_thr_self 432
#define SYS_thr_kill 433
#define SYS__umtx_op 454
#define SYS_thr_new 455
#define SYS_mmap 477
#define SYS_cpuset_getaffinity 487
#define SYS_openat 499

TEXT runtime·sys_umtx_op(SB),NOSPLIT,$0
	MOVD addr+0(FP), R0
	MOVW mode+8(FP), R1
	MOVW val+12(FP), R2
	MOVD uaddr1+16(FP), R3
	MOVD uaddr2+24(FP), R4
	MOVD $SYS__umtx_op, R8
	SVC
	SUB $20, R13
	MOVW	R0, ret+32(FP)
	RET

TEXT runtime·thr_new(SB),NOSPLIT,$0
	MOVD param+0(FP), R0
	MOVD size+8(FP), R1
	MOVW $SYS_thr_new, R8
	SVC
	MOVW	R0, ret+16(FP)
	RET

TEXT runtime·thr_start(SB),NOSPLIT,$0
	// set up g
	MOVD	R10, g_m(R11)
	MOVD	R11, g
	//BL runtime·stackcheck(SB)
	BL runtime·mstart(SB)

	MOVW $2, R8  // crash (not reached)
	MOVW R8, (R8)
	RET

TEXT runtime·exit(SB),NOSPLIT|NOFRAME,$0-4
	MOVW	code+0(FP), R0
	MOVD	$SYS_exit, R8
	SVC
	RET

// func exitThread(wait *uint32)
TEXT runtime·exitThread(SB),NOSPLIT|NOFRAME,$0-8
	MOVD	wait+0(FP), R0
	// We're done using the stack.
	MOVW	$0, R1
	STLRW	R1, (R0)
	MOVW	$0, R0	// exit code
	MOVD	$SYS_exit, R8
	SVC
	JMP	0(PC)

TEXT runtime·open(SB),NOSPLIT|NOFRAME,$0-20
	MOVD	$AT_FDCWD, R0
	MOVD	name+0(FP), R1
	MOVW	mode+8(FP), R2
	MOVW	perm+12(FP), R3
	MOVD	$SYS_openat, R8
	SVC
	CMN	$4095, R0
	BCC	done
	MOVW	$-1, R0
done:
	MOVW	R0, ret+16(FP)
	RET

TEXT runtime·closefd(SB),NOSPLIT|NOFRAME,$0-12
	MOVW	fd+0(FP), R0
	MOVD	$SYS_close, R8
	SVC
	CMN	$4095, R0
	BCC	done
	MOVW	$-1, R0
done:
	MOVW	R0, ret+8(FP)
	RET

TEXT runtime·write(SB),NOSPLIT|NOFRAME,$0-28
	MOVD	fd+0(FP), R0
	MOVD	p+8(FP), R1
	MOVW	n+16(FP), R2
	MOVD	$SYS_write, R8
	SVC
	CMN	$4095, R0
	BCC	done
	MOVW	$-1, R0
done:
	MOVW	R0, ret+24(FP)
	RET

TEXT runtime·read(SB),NOSPLIT|NOFRAME,$0-28
	MOVW	fd+0(FP), R0
	MOVD	p+8(FP), R1
	MOVW	n+16(FP), R2
	MOVD	$SYS_read, R8
	SVC
	CMN	$4095, R0
	BCC	done
	MOVW	$-1, R0
done:
	MOVW	R0, ret+24(FP)
	RET

TEXT runtime·usleep(SB),NOSPLIT,$24-4
	MOVWU	usec+0(FP), R3
	MOVD	R3, R5
	MOVW	$1000000, R4
	UDIV	R4, R3
	MOVD	R3, 8(RSP)
	MUL	R3, R4
	SUB	R4, R5
	MOVW	$1000, R4
	MUL	R4, R5
	MOVD	R5, 16(RSP)

	// nanosleep(&ts, 0)
	ADD	$8, RSP, R0
	MOVD	$0, R1
	MOVD	$SYS_nanosleep, R8
	SVC
	RET

TEXT runtime·raise(SB),NOSPLIT,$8
	MOVD $8(RSP), R0 // arg 1 &tid
	MOVD	$SYS_thr_self, R8
	SVC
	MOVW	8(RSP), R0	// arg 1 tid
	MOVW	sig+0(FP), R1	// arg 2
	MOVD	$SYS_thr_kill, R8
	SVC
	RET

TEXT runtime·raiseproc(SB),NOSPLIT|NOFRAME,$0
	MOVD	$SYS_getpid, R8
	SVC
	MOVW	R0, R0		// arg 1 pid
	MOVW	sig+0(FP), R1	// arg 2
	MOVD	$SYS_kill, R8
	SVC
	RET

TEXT runtime·setitimer(SB),NOSPLIT|NOFRAME,$0-24
	MOVW	mode+0(FP), R0
	MOVD	new+8(FP), R1
	MOVD	old+16(FP), R2
	MOVD	$SYS_setitimer, R8
	SVC
	RET

TEXT runtime·fallback_walltime(SB),NOSPLIT,$24-12
	MOVD	$CLOCK_REALTIME, R0
	MOVD	$8(RSP), R1
	MOVD	$SYS_clock_gettime, R8
	SVC
	MOVD	8(RSP), R3	// sec
	MOVD	16(RSP), R5	// nsec
	MOVD	R3, sec+0(FP)
	MOVW	R5, nsec+8(FP)
	RET

TEXT runtime·fallback_nanotime(SB),NOSPLIT,$24-8
	MOVD	$CLOCK_MONOTONIC, R0
	MOVD	$8(RSP), R1
	MOVD	$SYS_clock_gettime, R8
	SVC
	MOVD	8(RSP), R3	// sec
	MOVD	16(RSP), R5	// nsec
	// sec is in R3, nsec in R5
	// return nsec in R3
	MOVD	$1000000000, R4
	MUL	R4, R3
	ADD	R5, R3
	MOVD	R3, ret+0(FP)
	RET

TEXT runtime·asmSigaction(SB),NOSPLIT|NOFRAME,$0
	MOVD sig+0(FP), R0		// arg 1 sig
	MOVD new+8(FP), R1		// arg 2 act
	MOVD old+16(FP), R2		// arg 3 oact
	MOVD $SYS_sigaction, R8
	SVC
	MOVW R0, ret+24(FP)
	RET

// Call the function stored in _cgo_sigaction using the GCC calling convention.
TEXT runtime·callCgoSigaction(SB),NOSPLIT,$0
	MOVD	sig+0(FP), R0
	MOVD	new+8(FP), R1
	MOVD	old+16(FP), R2
	MOVD	 _cgo_sigaction(SB), R3
	BL	R3
	MOVW	R0, ret+24(FP)
	RET

TEXT runtime·sigfwd(SB),NOSPLIT,$0-32
	MOVD	sig+8(FP), R0
	MOVD	info+16(FP), R1
	MOVD	ctx+24(FP), R2
	MOVD	fn+0(FP), R11
	BL	(R11)
	RET

TEXT runtime·sigtramp(SB),NOSPLIT,$24
	// this might be called in external code context,
	// where g is not set.
	// first save R0, because runtime·load_g will clobber it
	MOVW	R0, 8(RSP)
	MOVBU	runtime·iscgo(SB), R0
	CMP	$0, R0
	BEQ	2(PC)
	BL	runtime·load_g(SB)

	MOVD	R1, 16(RSP)
	MOVD	R2, 24(RSP)
	MOVD	$runtime·sigtrampgo(SB), R0
	BL	(R0)
	RET

TEXT runtime·cgoSigtramp(SB),NOSPLIT,$0
	MOVD	$runtime·sigtramp(SB), R3
	B	(R3)

TEXT runtime·mmap(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R0
	MOVD	n+8(FP), R1
	MOVW	prot+16(FP), R2
	MOVW	flags+20(FP), R3
	MOVW	fd+24(FP), R4
	MOVW	off+28(FP), R5
	MOVD	$SYS_mmap, R8
	SVC
	CMN	$4095, R0
	BCC	ok
	NEG	R0,R0
	MOVD	$0, p+32(FP)
	MOVD	R0, err+40(FP)
	RET
ok:
	MOVD	R0, p+32(FP)
	MOVD	$0, err+40(FP)
	RET

TEXT runtime·munmap(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R0
	MOVD	n+8(FP), R1
	MOVD	$SYS_munmap, R8
	SVC
	CMN	$4095, R0
	BCC	cool
	MOVD	R0, 0xf0(R0)
cool:
	RET

TEXT runtime·madvise(SB),NOSPLIT|NOFRAME,$0
	MOVD	addr+0(FP), R0
	MOVD	n+8(FP), R1
	MOVW	flags+16(FP), R2
	MOVD	$SYS_madvise, R8
	SVC
	// ignore failure - maybe pages are locked
	RET

TEXT runtime·sysctl(SB),NOSPLIT,$0
	MOVD mib+0(FP), R0	// arg 1 - name
	MOVD miblen+8(FP), R1	// arg 2 - namelen
	MOVD out+16(FP), R2	// arg 3 - oldp
	MOVD size+24(FP), R3	// arg 4 - oldlenp
	MOVD dst+32(FP), R4	// arg 5 - newp
	MOVD ndst+40(FP), R5	// arg 6 - newlen
	MOVD $SYS___sysctl, R8
	SVC
	MOVW	R0, ret+48(FP)
	RET

TEXT runtime·sigaltstack(SB),NOSPLIT|NOFRAME,$0
	MOVD	new+0(FP), R0
	MOVD	old+8(FP), R1
	MOVD	$SYS_sigaltstack, R8
	SVC
	CMN	$4095, R0
	BCC	ok
	MOVD	$0, R0
	MOVD	R0, (R0)	// crash
ok:
	RET

TEXT runtime·osyield(SB),NOSPLIT|NOFRAME,$0
	MOVD	$SYS_sched_yield, R8
	SVC
	RET

TEXT runtime·sigprocmask(SB),NOSPLIT|NOFRAME,$0-28
	MOVD	how+0(FP), R0
	MOVD	new+8(FP), R1
	MOVD	old+16(FP), R2
	MOVD	$SYS_sigprocmask, R8
	SVC
	CMN	$4095, R0
	BCC	done
	MOVD	$0, R0
	MOVD	R0, (R0)	// crash
done:
	RET

// int cpuset_getaffinity(level int, which int, id int64, size int, mask *byte)
TEXT runtime·cpuset_getaffinity(SB),NOSPLIT|NOFRAME,$0-44
	MOVD	level+0(FP), R0
	MOVD	which+8(FP), R1
	MOVD	id+16(FP), R2
	MOVD	size+24(FP), R3
	MOVD	mask+32(FP), R4
	MOVD	$SYS_cpuset_getaffinity, R8
	SVC
	MOVW	R0, ret+40(FP)
	RET

// int32 runtime·kqueue(void)
TEXT runtime·kqueue(SB),NOSPLIT|NOFRAME,$0
	MOVD $SYS_kqueue, R8
	SVC
	MOVW	R0, ret+0(FP)
	RET

// int32 runtime·kevent(int kq, Kevent *changelist, int nchanges, Kevent *eventlist, int nevents, Timespec *timeout)
TEXT runtime·kevent(SB),NOSPLIT|NOFRAME,$0
	MOVD kq+0(FP), R0	// kq
	MOVD ch+8(FP), R1	// changelist
	MOVD nch+16(FP), R2	// nchanges
	MOVD ev+24(FP), R3	// eventlist
	MOVD nev+32(FP), R4	// nevents
	MOVD ts+40(FP), R5	// timeout
	MOVD $SYS_kevent, R8
	SVC
	SUB $20, R13
	MOVW	R0, ret+48(FP)
	RET

// void runtime·closeonexec(int32 fd);
TEXT runtime·closeonexec(SB),NOSPLIT|NOFRAME,$0
	MOVW	fd+0(FP), R0  // fd
	MOVD	$2, R1	// F_SETFD
	MOVD	$1, R2	// FD_CLOEXEC
	MOVD	$SYS_fcntl, R8
	SVC
	RET
