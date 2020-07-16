import typography, streams, flippy

proc loadFont*(path: static[string]) =
    const data = staticRead(path)
    let str = newStringStream(data)

    let font = readFontTtf(str)

    font.size = 16

    let image = font.getGlyphImage("A")
    
    echo font.name
    echo font.glyphs["A"].path
    echo $image.width & " x " & $image.height
    echo image.data

    image.save("itisA.png")