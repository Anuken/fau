#MATH

type Vec2* = object
    x, y: float

#3x3 matrix for 2D transformations
const M00 = 0
const M01 = 3
const M02 = 6
const M10 = 1
const M11 = 4
const M12 = 7
const M20 = 2
const M21 = 5
const M22 = 8

type Mat* = object
    val: array[9, float32]

proc newMat*(): Mat = 
    result = Mat(val: [1'f32, 0, 0, 0, 1, 0, 0, 0, 1])

proc `*`*(self: Mat, m: Mat): Mat =
    return Mat(val: [
        self.val[M00] * m.val[M00] + self.val[M01] * m.val[M10] + self.val[M02] * m.val[M20], 
        self.val[M00] * m.val[M01] + self.val[M01] * m.val[M11] + self.val[M02] * m.val[M21],
        self.val[M00] * m.val[M02] + self.val[M01] * m.val[M12] + self.val[M02] * m.val[M22],

        self.val[M10] * m.val[M00] + self.val[M11] * m.val[M10] + self.val[M12] * m.val[M20],
        self.val[M10] * m.val[M01] + self.val[M11] * m.val[M11] + self.val[M12] * m.val[M21],
        self.val[M10] * m.val[M02] + self.val[M11] * m.val[M12] + self.val[M12] * m.val[M22],

        self.val[M20] * m.val[M00] + self.val[M21] * m.val[M10] + self.val[M22] * m.val[M20],
        self.val[M20] * m.val[M01] + self.val[M21] * m.val[M11] + self.val[M22] * m.val[M21],
        self.val[M20] * m.val[M02] + self.val[M21] * m.val[M12] + self.val[M22] * m.val[M22]
    ])

proc det*(self: Mat): float32 =
    return self.val[M00] * self.val[M11] * self.val[M22] + self.val[M01] * self.val[M12] * self.val[M20] + self.val[M02] * self.val[M10] * self.val[M21] -
    self.val[M00]* self.val[M12] * self.val[M21] - val[M01] * self.val[M10] * self.val[M22] - self.val[M02] * self.val[M11] * self.val[M20]