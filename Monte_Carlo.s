// Nikolas Poholik
// 3/22/24
//------------------------------------------------------------------------------

.text
.global _start

//-------------------------------------------------------------------------------

_start:
//------------------------------------------------
    // One Hundred Point Trial:
    // movz x0, #100, lsl #0 
    //-------------------------
    // Ten Thousand Point Trial:
    // movz x0, #10000, lsl #0 
    //-------------------------
    // One Hundred Thousand Point Trial:
    // movz X0, 0x86A0, lsl #0
    // movk X0, 0x0001, lsl #16
    //-------------------------
    // One Million Point Trial:
    movz X0, 0x4240, lsl #0
    movk X0, 0x000F, lsl #16
    //-------------------------
//------------------------------------------------
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
//* 1. Upon one complete run of 'repeat', there will be a set of two random float point numbers from [-1,1]
//* 2. These numbers will have to be verified as falling within the unit circle ( the range [-1.1] is a square, x^2 + y^2 <= 1 is within the unit circle within that square)
//*             Area of square = l * w = 2 * 2 = 4 units^2
//*             Area of unit circle = (pi)
//*
//*             The equation for the unit circle is: x^2+y^2=1
//*             Therefore, checking if a point is within the unit circle involves checking if x^2 + y^2 <= 1 (From unit circle equation)
//* 3. For any valid point within the unit circle, add it to a running sum alongside a counter of how many valid points.
//*             * Regardless of outcome, a counter of how many square points will always be incremented (sincce each rand number is from [-1,1].
//* 4. After each point, move onto the next available point from the function; run ONLY so long as the max iterations of points is not exceeded.
//* 5. The final calculation, from the areas previously claculated, will be:
//*             pi = 4 * (points inside of the circle) / (total number of points)
//****************************************************************************
// Define the counter for total points (square) and points within circle (unit circle)
mov x14, #0 // x14 = # of total points
mov x15, #0 // x15 = # of points inside circle

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

    fmul d3, d0, d0 // get x^2

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

    fmul d4, d0, d0 // get y^2

    fadd d5, d3, d4 // get x^2 + y^2 

    mov x12, #1 
    scvtf d6, x12 // convert 1 to floating point 

    add x14, x14, x12 //increment total num of points by 1

    fcmp d5, d6
    b.gt skip

    add x15, x15, x12 // increment points within circle by 1

    skip:
 //   ldr x0, =string // Load format string for printf
 //   ldr x8, =var // get address of variables
 //   ldr x2, [x8, 0] // Paramter 2 - the floating point version of the number
 //   mov x1, x10
 //   bl printf // x0 - format string, x1 - first decimal, d0 - first floating point

    ldr x8, =count // decrement the repeat counter
    ldr x10, [x8, 0]
    sub x10, x10, #1
    str x10, [x8, 0]
    cbz x10, _calculate
    b repeat

_calculate:
    mov x1, #4 // move 4 into a reg
    scvtf d0, x1 // convert 4 to floating point
    scvtf d2, x15 // convert # of points in circle to floating point
    scvtf d3, x14 // convert # of points outside circle to floating point
    fmul d0, d0, d2 // do 4 * # points in circle
    fdiv d0, d0, d3 // final calculations of pi ( 4 * # points in circle / # total points)

    // Print value
    ldr x0, =string
    ldr x8, =var
    str d0, [x8, 0]
    bl printf

// Exit code:
_exit:
        mov x8, #94
        mov x0, #0
        svc #0

//----------------------------------------------------------------------------

.data
//string:
//.asciz "Num: %d: %lld %lf\n"
//.bss // variable

string:
.asciz "Pi: %lf\n"

var:
        .zero 8
        .zero 8
count:
        .zero 8
divisor:
        .zero 8
