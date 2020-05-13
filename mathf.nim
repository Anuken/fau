

type Vec2* = object
    x, y: float

#3x3 matrix for 2D transformations
type Mat* = object
    values: array[9, float]