// Nikolas Poholik
// 3/22/24
//------------------------------------------------------------------------------

.text
.global _start

//-------------------------------------------------------------------------------

_start:
    mov x0, #10
    ldr x8, =count

    str x0, [x8, 0]

    movz x0, #65535, lsl #0 // build a constant that is 7FFF FFFF FFFF FFFF
    movk x0, #65535, lsl #16
    movk x0, #65535, lsl #32
    movk x0, #32767, lsl #48
    scvtf d1, x0
    ldr x0, =divisor
    str d1, [x0, 0]     // Store this constant in the divisor variable

// Process given to generate random #'s

//**************************************************************************

//* The main addition to this program is the following:
//* 1. Upon one complete run of 'repeat', there will be a set of 10 random float point numbers from [-1,1]
//* 2. These numbers will have to be verified as falling within the unit circle ( the range [-1.1] is a square, we need to truncate the four corners)
//*             Area of square = l * w = 2 * 2 = 4 units^2
//*             Area of unit circle = (pi)
//*
//*             The equation for the unit circle is: x^2+y^2=1
//*             Therefore, checking if a point is within the unit circle involves checking if x^2 + y^2 <= 1 (From circle unit circle equation)
//*
//* 3. For any valid point within the unit circle, add it to a running sum alongside a counter of how many valid points.
//*             * Regardless of outcome, a counter of how many square points will always be incremented (sincce each rand number is from [-1,1].
//* 4. After each point, move onto the next available point from the function run ONLY so long as the max iterations of points is not exceeded.
//* 5. The final calculation, from the areas previously claculated, will be:
//*             pi = 4 * (points inside of the circle) / (total number of points)

//****************************************************************************

repeat:
    mov x8, #278 // Setup for Syscall 278 - getrandom
    ldr x0, =var // buffer address
    mov x1, #8 // 8 bytes of randomness
    mov x2, #0 // flags ?
    svc #0

    ldr x8, =var // get address of variables
    ldr x9, [x8, 0] // load random number
    scvtf d0, x9 // convert to double percinsion
    str d0, [x8, 8] // store double percision

    ldr x0, =divisor // Load divisor from ram
    ldr d1, [x0, 0]
    fdiv d0, d0, d1 // make random number be between -1 and 1

    ldr x0, =string // Load format string for printf
    ldr x8, =var // get address of variables
    ldr x2, [x8, 0] // Paramter 2 - the floating point version of the number
    mov x1, x10
    bl printf // x0 - format string, x1 - first decimal, d0 - first floating point

    ldr x8, =count // decrement the repeat counter
    ldr x10, [x8, 0]
    sub x10, x10, #1
    str x10, [x8, 0]
    cbz x10, _exit
    b repeat

// Exit code:
_exit:
        mov x8, #94
        mov x0, #0
        svc #0

//----------------------------------------------------------------------------

.data
string:
.asciz "Num: %d: %lld %lf\n"
//.bss // variable

var:
        .zero 8
        .zero 8
count:
        .zero 8
divisor:
        .zero 8
