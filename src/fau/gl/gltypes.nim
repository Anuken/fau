
# Types
type
  GLbitfield* = uint32
  GLboolean* = bool
  GLbyte* = int8
  GLchar* = char
  GLcharARB* = byte
  GLclampd* = float64
  GLclampf* = float32
  GLclampx* = int32
  GLdouble* = float64
  GLenum* = uint32
  GLfixed* = int32
  GLfloat* = float32
  GLhalf* = uint16
  GLhalfARB* = uint16
  GLhalfNV* = uint16
  GLhandleARB* = uint32
  GLint* = int32
  GLint64* = int64
  GLint64EXT* = int64
  GLintptr* = int
  GLintptrARB* = int
  GLshort* = int16
  GLsizei* = int32
  GLsizeiptr* = int
  GLsizeiptrARB* = int
  GLsync* = distinct pointer
  GLubyte* = uint8
  GLuint* = uint32
  GLuint64* = uint64
  GLuint64EXT* = uint64
  GLushort* = uint16
  GLvoid* = pointer


# Enums
const
  GlFalse* = 0
  GlInvalidIndex*: uint32 = uint32(0xFFFFFFFF)
  GlNone* = 0
  GlNoneOes* = 0
  GlNoError* = 0
  GlOne* = 1
  GlTimeoutIgnored*: uint64 = 0xFFFFFFFFFFFFFFFF'u64
  GlTrue* = 1
  GlZero* = 0
  GlDepthBufferBit*: GLenum = GLenum(0x00000100)
  GlStencilBufferBit*: GLenum = GLenum(0x00000400)
  GlColorBufferBit*: GLenum = GLenum(0x00004000)
  GlPoints*: GLenum = GLenum(0x0000)
  GlLines*: GLenum = GLenum(0x0001)
  GlLineLoop*: GLenum = GLenum(0x0002)
  GlLineStrip*: GLenum = GLenum(0x0003)
  GlTriangles*: GLenum = GLenum(0x0004)
  GlTriangleStrip*: GLenum = GLenum(0x0005)
  GlTriangleFan*: GLenum = GLenum(0x0006)
  GlSrcColor*: GLenum = GLenum(0x0300)
  GlOneMinusSrcColor*: GLenum = GLenum(0x0301)
  GlSrcAlpha*: GLenum = GLenum(0x0302)
  GlOneMinusSrcAlpha*: GLenum = GLenum(0x0303)
  GlDstAlpha*: GLenum = GLenum(0x0304)
  GlOneMinusDstAlpha*: GLenum = GLenum(0x0305)
  GlDstColor*: GLenum = GLenum(0x0306)
  GlOneMinusDstColor*: GLenum = GLenum(0x0307)
  GlSrcAlphaSaturate*: GLenum = GLenum(0x0308)
  GlFuncAdd*: GLenum = GLenum(0x8006)
  GlBlendEquation*: GLenum = GLenum(0x8009)
  GlBlendEquationRgb*: GLenum = GLenum(0x8009)
  GlBlendEquationAlpha*: GLenum = GLenum(0x883D)
  GlFuncSubtract*: GLenum = GLenum(0x800A)
  GlFuncReverseSubtract*: GLenum = GLenum(0x800B)
  GlBlendDstRgb*: GLenum = GLenum(0x80C8)
  GlBlendSrcRgb*: GLenum = GLenum(0x80C9)
  GlBlendDstAlpha*: GLenum = GLenum(0x80CA)
  GlBlendSrcAlpha*: GLenum = GLenum(0x80CB)
  GlConstantColor*: GLenum = GLenum(0x8001)
  GlOneMinusConstantColor*: GLenum = GLenum(0x8002)
  GlConstantAlpha*: GLenum = GLenum(0x8003)
  GlOneMinusConstantAlpha*: GLenum = GLenum(0x8004)
  GlBlendColor*: GLenum = GLenum(0x8005)
  GlArrayBuffer*: GLenum = GLenum(0x8892)
  GlElementArrayBuffer*: GLenum = GLenum(0x8893)
  GlArrayBufferBinding*: GLenum = GLenum(0x8894)
  GlElementArrayBufferBinding*: GLenum = GLenum(0x8895)
  GlStreamDraw*: GLenum = GLenum(0x88E0)
  GlStaticDraw*: GLenum = GLenum(0x88E4)
  GlDynamicDraw*: GLenum = GLenum(0x88E8)
  GlBufferSize*: GLenum = GLenum(0x8764)
  GlBufferUsage*: GLenum = GLenum(0x8765)
  GlCurrentVertexAttrib*: GLenum = GLenum(0x8626)
  GlFront*: GLenum = GLenum(0x0404)
  GlBack*: GLenum = GLenum(0x0405)
  GlFrontAndBack*: GLenum = GLenum(0x0408)
  GlTexture2d*: GLenum = GLenum(0x0DE1)
  GlCullFace*: GLenum = GLenum(0x0B44)
  GlBlend*: GLenum = GLenum(0x0BE2)
  GlDither*: GLenum = GLenum(0x0BD0)
  GlStencilTest*: GLenum = GLenum(0x0B90)
  GlDepthTest*: GLenum = GLenum(0x0B71)
  GlScissorTest*: GLenum = GLenum(0x0C11)
  GlPolygonOffsetFill*: GLenum = GLenum(0x8037)
  GlSampleAlphaToCoverage*: GLenum = GLenum(0x809E)
  GlSampleCoverage*: GLenum = GLenum(0x80A0)
  GlInvalidEnum*: GLenum = GLenum(0x0500)
  GlInvalidValue*: GLenum = GLenum(0x0501)
  GlInvalidOperation*: GLenum = GLenum(0x0502)
  GlOutOfMemory*: GLenum = GLenum(0x0505)
  GlCw*: GLenum = GLenum(0x0900)
  GlCcw*: GLenum = GLenum(0x0901)
  GlLineWidth*: GLenum = GLenum(0x0B21)
  GlAliasedPointSizeRange*: GLenum = GLenum(0x846D)
  GlAliasedLineWidthRange*: GLenum = GLenum(0x846E)
  GlCullFaceMode*: GLenum = GLenum(0x0B45)
  GlFrontFace*: GLenum = GLenum(0x0B46)
  GlDepthRange*: GLenum = GLenum(0x0B70)
  GlDepthWritemask*: GLenum = GLenum(0x0B72)
  GlDepthClearValue*: GLenum = GLenum(0x0B73)
  GlDepthFunc*: GLenum = GLenum(0x0B74)
  GlStencilClearValue*: GLenum = GLenum(0x0B91)
  GlStencilFunc*: GLenum = GLenum(0x0B92)
  GlStencilFail*: GLenum = GLenum(0x0B94)
  GlStencilPassDepthFail*: GLenum = GLenum(0x0B95)
  GlStencilPassDepthPass*: GLenum = GLenum(0x0B96)
  GlStencilRef*: GLenum = GLenum(0x0B97)
  GlStencilValueMask*: GLenum = GLenum(0x0B93)
  GlStencilWritemask*: GLenum = GLenum(0x0B98)
  GlStencilBackFunc*: GLenum = GLenum(0x8800)
  GlStencilBackFail*: GLenum = GLenum(0x8801)
  GlStencilBackPassDepthFail*: GLenum = GLenum(0x8802)
  GlStencilBackPassDepthPass*: GLenum = GLenum(0x8803)
  GlStencilBackRef*: GLenum = GLenum(0x8CA3)
  GlStencilBackValueMask*: GLenum = GLenum(0x8CA4)
  GlStencilBackWritemask*: GLenum = GLenum(0x8CA5)
  GlViewport*: GLenum = GLenum(0x0BA2)
  GlScissorBox*: GLenum = GLenum(0x0C10)
  GlColorClearValue*: GLenum = GLenum(0x0C22)
  GlColorWritemask*: GLenum = GLenum(0x0C23)
  GlUnpackAlignment*: GLenum = GLenum(0x0CF5)
  GlPackAlignment*: GLenum = GLenum(0x0D05)
  GlMaxTextureSize*: GLenum = GLenum(0x0D33)
  GlMaxViewportDims*: GLenum = GLenum(0x0D3A)
  GlSubpixelBits*: GLenum = GLenum(0x0D50)
  GlRedBits*: GLenum = GLenum(0x0D52)
  GlGreenBits*: GLenum = GLenum(0x0D53)
  GlBlueBits*: GLenum = GLenum(0x0D54)
  GlAlphaBits*: GLenum = GLenum(0x0D55)
  GlDepthBits*: GLenum = GLenum(0x0D56)
  GlStencilBits*: GLenum = GLenum(0x0D57)
  GlPolygonOffsetUnits*: GLenum = GLenum(0x2A00)
  GlPolygonOffsetFactor*: GLenum = GLenum(0x8038)
  GlTextureBinding2d*: GLenum = GLenum(0x8069)
  GlSampleBuffers*: GLenum = GLenum(0x80A8)
  GlSamples*: GLenum = GLenum(0x80A9)
  GlSampleCoverageValue*: GLenum = GLenum(0x80AA)
  GlSampleCoverageInvert*: GLenum = GLenum(0x80AB)
  GlNumCompressedTextureFormats*: GLenum = GLenum(0x86A2)
  GlCompressedTextureFormats*: GLenum = GLenum(0x86A3)
  GlDontCare*: GLenum = GLenum(0x1100)
  GlFastest*: GLenum = GLenum(0x1101)
  GlNicest*: GLenum = GLenum(0x1102)
  GlGenerateMipmapHint*: GLenum = GLenum(0x8192)
  cGlByte*: GLenum = GLenum(0x1400)
  GlUnsignedByte*: GLenum = GLenum(0x1401)
  cGlShort*: GLenum = GLenum(0x1402)
  GlUnsignedShort*: GLenum = GLenum(0x1403)
  cGlInt*: GLenum = GLenum(0x1404)
  GlUnsignedInt*: GLenum = GLenum(0x1405)
  cGlFloat*: GLenum = GLenum(0x1406)
  cGlFixed*: GLenum = GLenum(0x140C)
  GlDepthComponent*: GLenum = GLenum(0x1902)
  GlAlpha*: GLenum = GLenum(0x1906)
  GlRgb*: GLenum = GLenum(0x1907)
  GlRgba*: GLenum = GLenum(0x1908)
  GlLuminance*: GLenum = GLenum(0x1909)
  GlLuminanceAlpha*: GLenum = GLenum(0x190A)
  GlUnsignedShort4444*: GLenum = GLenum(0x8033)
  GlUnsignedShort5551*: GLenum = GLenum(0x8034)
  GlUnsignedShort565*: GLenum = GLenum(0x8363)
  GlFragmentShader*: GLenum = GLenum(0x8B30)
  GlVertexShader*: GLenum = GLenum(0x8B31)
  GlMaxVertexAttribs*: GLenum = GLenum(0x8869)
  GlMaxVertexUniformVectors*: GLenum = GLenum(0x8DFB)
  GlMaxVaryingVectors*: GLenum = GLenum(0x8DFC)
  GlMaxCombinedTextureImageUnits*: GLenum = GLenum(0x8B4D)
  GlMaxVertexTextureImageUnits*: GLenum = GLenum(0x8B4C)
  GlMaxTextureImageUnits*: GLenum = GLenum(0x8872)
  GlMaxFragmentUniformVectors*: GLenum = GLenum(0x8DFD)
  GlShaderType*: GLenum = GLenum(0x8B4F)
  GlDeleteStatus*: GLenum = GLenum(0x8B80)
  GlLinkStatus*: GLenum = GLenum(0x8B82)
  GlValidateStatus*: GLenum = GLenum(0x8B83)
  GlAttachedShaders*: GLenum = GLenum(0x8B85)
  GlActiveUniforms*: GLenum = GLenum(0x8B86)
  GlActiveUniformMaxLength*: GLenum = GLenum(0x8B87)
  GlActiveAttributes*: GLenum = GLenum(0x8B89)
  GlActiveAttributeMaxLength*: GLenum = GLenum(0x8B8A)
  GlShadingLanguageVersion*: GLenum = GLenum(0x8B8C)
  GlCurrentProgram*: GLenum = GLenum(0x8B8D)
  GlNever*: GLenum = GLenum(0x0200)
  GlLess*: GLenum = GLenum(0x0201)
  GlEqual*: GLenum = GLenum(0x0202)
  GlLequal*: GLenum = GLenum(0x0203)
  GlGreater*: GLenum = GLenum(0x0204)
  GlNotequal*: GLenum = GLenum(0x0205)
  GlGequal*: GLenum = GLenum(0x0206)
  GlAlways*: GLenum = GLenum(0x0207)
  GlKeep*: GLenum = GLenum(0x1E00)
  GlReplace*: GLenum = GLenum(0x1E01)
  GlIncr*: GLenum = GLenum(0x1E02)
  GlDecr*: GLenum = GLenum(0x1E03)
  GlInvert*: GLenum = GLenum(0x150A)
  GlIncrWrap*: GLenum = GLenum(0x8507)
  GlDecrWrap*: GLenum = GLenum(0x8508)
  GlVendor*: GLenum = GLenum(0x1F00)
  GlRenderer*: GLenum = GLenum(0x1F01)
  GlVersion*: GLenum = GLenum(0x1F02)
  GlExtensions*: GLenum = GLenum(0x1F03)
  GlNearest*: GLenum = GLenum(0x2600)
  GlLinear*: GLenum = GLenum(0x2601)
  GlNearestMipmapNearest*: GLenum = GLenum(0x2700)
  GlLinearMipmapNearest*: GLenum = GLenum(0x2701)
  GlNearestMipmapLinear*: GLenum = GLenum(0x2702)
  GlLinearMipmapLinear*: GLenum = GLenum(0x2703)
  GlTextureMagFilter*: GLenum = GLenum(0x2800)
  GlTextureMinFilter*: GLenum = GLenum(0x2801)
  GlTextureWrapS*: GLenum = GLenum(0x2802)
  GlTextureWrapT*: GLenum = GLenum(0x2803)
  GlTexture*: GLenum = GLenum(0x1702)
  GlTextureCubeMap*: GLenum = GLenum(0x8513)
  GlTextureBindingCubeMap*: GLenum = GLenum(0x8514)
  GlTextureCubeMapPositiveX*: GLenum = GLenum(0x8515)
  GlTextureCubeMapNegativeX*: GLenum = GLenum(0x8516)
  GlTextureCubeMapPositiveY*: GLenum = GLenum(0x8517)
  GlTextureCubeMapNegativeY*: GLenum = GLenum(0x8518)
  GlTextureCubeMapPositiveZ*: GLenum = GLenum(0x8519)
  GlTextureCubeMapNegativeZ*: GLenum = GLenum(0x851A)
  GlMaxCubeMapTextureSize*: GLenum = GLenum(0x851C)
  GlTexture0*: GLenum = GLenum(0x84C0)
  GlTexture1*: GLenum = GLenum(0x84C1)
  GlTexture2*: GLenum = GLenum(0x84C2)
  GlTexture3*: GLenum = GLenum(0x84C3)
  GlTexture4*: GLenum = GLenum(0x84C4)
  GlTexture5*: GLenum = GLenum(0x84C5)
  GlTexture6*: GLenum = GLenum(0x84C6)
  GlTexture7*: GLenum = GLenum(0x84C7)
  GlTexture8*: GLenum = GLenum(0x84C8)
  GlTexture9*: GLenum = GLenum(0x84C9)
  GlTexture10*: GLenum = GLenum(0x84CA)
  GlTexture11*: GLenum = GLenum(0x84CB)
  GlTexture12*: GLenum = GLenum(0x84CC)
  GlTexture13*: GLenum = GLenum(0x84CD)
  GlTexture14*: GLenum = GLenum(0x84CE)
  GlTexture15*: GLenum = GLenum(0x84CF)
  GlTexture16*: GLenum = GLenum(0x84D0)
  GlTexture17*: GLenum = GLenum(0x84D1)
  GlTexture18*: GLenum = GLenum(0x84D2)
  GlTexture19*: GLenum = GLenum(0x84D3)
  GlTexture20*: GLenum = GLenum(0x84D4)
  GlTexture21*: GLenum = GLenum(0x84D5)
  GlTexture22*: GLenum = GLenum(0x84D6)
  GlTexture23*: GLenum = GLenum(0x84D7)
  GlTexture24*: GLenum = GLenum(0x84D8)
  GlTexture25*: GLenum = GLenum(0x84D9)
  GlTexture26*: GLenum = GLenum(0x84DA)
  GlTexture27*: GLenum = GLenum(0x84DB)
  GlTexture28*: GLenum = GLenum(0x84DC)
  GlTexture29*: GLenum = GLenum(0x84DD)
  GlTexture30*: GLenum = GLenum(0x84DE)
  GlTexture31*: GLenum = GLenum(0x84DF)
  GlActiveTexture*: GLenum = GLenum(0x84E0)
  GlRepeat*: GLenum = GLenum(0x2901)
  GlClampToEdge*: GLenum = GLenum(0x812F)
  GlMirroredRepeat*: GLenum = GLenum(0x8370)
  GlFloatVec2*: GLenum = GLenum(0x8B50)
  GlFloatVec3*: GLenum = GLenum(0x8B51)
  GlFloatVec4*: GLenum = GLenum(0x8B52)
  GlIntVec2*: GLenum = GLenum(0x8B53)
  GlIntVec3*: GLenum = GLenum(0x8B54)
  GlIntVec4*: GLenum = GLenum(0x8B55)
  GlBool*: GLenum = GLenum(0x8B56)
  GlBoolVec2*: GLenum = GLenum(0x8B57)
  GlBoolVec3*: GLenum = GLenum(0x8B58)
  GlBoolVec4*: GLenum = GLenum(0x8B59)
  GlFloatMat2*: GLenum = GLenum(0x8B5A)
  GlFloatMat3*: GLenum = GLenum(0x8B5B)
  GlFloatMat4*: GLenum = GLenum(0x8B5C)
  GlSampler2d*: GLenum = GLenum(0x8B5E)
  GlSamplerCube*: GLenum = GLenum(0x8B60)
  GlVertexAttribArrayEnabled*: GLenum = GLenum(0x8622)
  GlVertexAttribArraySize*: GLenum = GLenum(0x8623)
  GlVertexAttribArrayStride*: GLenum = GLenum(0x8624)
  GlVertexAttribArrayType*: GLenum = GLenum(0x8625)
  GlVertexAttribArrayNormalized*: GLenum = GLenum(0x886A)
  GlVertexAttribArrayPointer*: GLenum = GLenum(0x8645)
  GlVertexAttribArrayBufferBinding*: GLenum = GLenum(0x889F)
  GlImplementationColorReadType*: GLenum = GLenum(0x8B9A)
  GlImplementationColorReadFormat*: GLenum = GLenum(0x8B9B)
  GlCompileStatus*: GLenum = GLenum(0x8B81)
  GlInfoLogLength*: GLenum = GLenum(0x8B84)
  GlShaderSourceLength*: GLenum = GLenum(0x8B88)
  GlShaderCompiler*: GLenum = GLenum(0x8DFA)
  GlShaderBinaryFormats*: GLenum = GLenum(0x8DF8)
  GlNumShaderBinaryFormats*: GLenum = GLenum(0x8DF9)
  GlLowFloat*: GLenum = GLenum(0x8DF0)
  GlMediumFloat*: GLenum = GLenum(0x8DF1)
  GlHighFloat*: GLenum = GLenum(0x8DF2)
  GlLowInt*: GLenum = GLenum(0x8DF3)
  GlMediumInt*: GLenum = GLenum(0x8DF4)
  GlHighInt*: GLenum = GLenum(0x8DF5)
  GlFramebuffer*: GLenum = GLenum(0x8D40)
  GlRenderbuffer*: GLenum = GLenum(0x8D41)
  GlRgba4*: GLenum = GLenum(0x8056)
  GlRgb5A1*: GLenum = GLenum(0x8057)
  GlRgb565*: GLenum = GLenum(0x8D62)
  GlDepthComponent16*: GLenum = GLenum(0x81A5)
  GlStencilIndex8*: GLenum = GLenum(0x8D48)
  GlRenderbufferWidth*: GLenum = GLenum(0x8D42)
  GlRenderbufferHeight*: GLenum = GLenum(0x8D43)
  GlRenderbufferInternalFormat*: GLenum = GLenum(0x8D44)
  GlRenderbufferRedSize*: GLenum = GLenum(0x8D50)
  GlRenderbufferGreenSize*: GLenum = GLenum(0x8D51)
  GlRenderbufferBlueSize*: GLenum = GLenum(0x8D52)
  GlRenderbufferAlphaSize*: GLenum = GLenum(0x8D53)
  GlRenderbufferDepthSize*: GLenum = GLenum(0x8D54)
  GlRenderbufferStencilSize*: GLenum = GLenum(0x8D55)
  GlFramebufferAttachmentObjectType*: GLenum = GLenum(0x8CD0)
  GlFramebufferAttachmentObjectName*: GLenum = GLenum(0x8CD1)
  GlFramebufferAttachmentTextureLevel*: GLenum = GLenum(0x8CD2)
  GlFramebufferAttachmentTextureCubeMapFace*: GLenum = GLenum(0x8CD3)
  GlColorAttachment0*: GLenum = GLenum(0x8CE0)
  GlDepthAttachment*: GLenum = GLenum(0x8D00)
  GlStencilAttachment*: GLenum = GLenum(0x8D20)
  GlFramebufferComplete*: GLenum = GLenum(0x8CD5)
  GlFramebufferIncompleteAttachment*: GLenum = GLenum(0x8CD6)
  GlFramebufferIncompleteMissingAttachment*: GLenum = GLenum(0x8CD7)
  GlFramebufferIncompleteDimensions*: GLenum = GLenum(0x8CD9)
  GlFramebufferUnsupported*: GLenum = GLenum(0x8CDD)
  GlFramebufferBinding*: GLenum = GLenum(0x8CA6)
  GlRenderbufferBinding*: GLenum = GLenum(0x8CA7)
  GlMaxRenderbufferSize*: GLenum = GLenum(0x84E8)
  GlInvalidFramebufferOperation*: GLenum = GLenum(0x0506)