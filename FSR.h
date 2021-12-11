#if (USE_FSR == 1)

//---------------------------------------------------------------------- FSR BEGIN
// Based on: https://www.shadertoy.com/view/stXSWB

#define PI 3.1415923693
#define SINE(x) sin(.5 * PI * (x - .5)) + 1.
#define COSINE(x) 1. - cos(.5 * PI * x)

texture BufferATex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

sampler BufferASampler
{
	Texture = BufferATex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

//---------------------------------------------------------------------- FSR Buffer A (Output to be used in Main, should use s0 as input)

/**** EASU ****/
void FsrEasuCon(
    out float4 con0,
    out float4 con1,
    out float4 con2,
    out float4 con3,
    // This the rendered image resolution being upscaled
    float2 inputViewportInPixels,
    // This is the resolution of the resource containing the input image (useful for dynamic resolution)
    float2 inputSizeInPixels,
    // This is the display resolution which the input image gets upscaled to
    float2 outputSizeInPixels
)
{
    // Output integer position to a pixel position in viewport.
    con0 = float4(
        inputViewportInPixels.x / outputSizeInPixels.x,
        inputViewportInPixels.y / outputSizeInPixels.y,
        mad(.5, inputViewportInPixels.x / outputSizeInPixels.x, -.5),
        mad(.5, inputViewportInPixels.y / outputSizeInPixels.y, -.5)
    );
    // Viewport pixel position to normalized image space.
    // This is used to get upper-left of 'F' tap.
    con1 = float4(1, 1, 1, -1) / inputSizeInPixels.xyxy;
    // Centers of gather4, first offset from upper-left of 'F'.
    //      +---+---+
    //      |   |   |
    //      +--(0)--+
    //      | b | c |
    //  +---F---+---+---+
    //  | e | f | g | h |
    //  +--(1)--+--(2)--+
    //  | i | j | k | l |
    //  +---+---+---+---+
    //      | n | o |
    //      +--(3)--+
    //      |   |   |
    //      +---+---+
    // These are from (0) instead of 'F'.
    con2 = float4(-1, 2, 1, 2) / inputSizeInPixels.xyxy;
    con3 = float4(0, 4, 0, 0) / inputSizeInPixels.xyxy;
}

// Filtering for a given tap for the scalar.
void FsrEasuTapF(
    inout float3 aC, // Accumulated color, with negative lobe.
    inout float aW, // Accumulated weight.
    float2 off, // Pixel offset from resolve position to tap.
    float2 dir, // Gradient direction.
    float2 len, // Length.
    float lob, // Negative lobe strength.
    float clp, // Clipping point.
    float3 c
)
{
    // Tap color.
    // Rotate offset by direction.
    float2 v = float2(dot(off, dir), dot(off, float2(-dir.y, dir.x)));
    // Anisotropy.
    v *= len;
    // Compute distance^2.
    float d2 = min(dot(v, v), clp);
    // Limit to the window as at corner, 2 taps can easily be outside.
    // Approximation of lancos2 without sin() or rcp(), or sqrt() to get x.
    //  (25/16 * (2/5 * x^2 - 1)^2 - (25/16 - 1)) * (1/4 * x^2 - 1)^2
    //  |_______________________________________|   |_______________|
    //                   base                             window
    // The general form of the 'base' is,
    //  (a*(b*x^2-1)^2-(a-1))
    // Where 'a=1/(2*b-b^2)' and 'b' moves around the negative lobe.
    float wB = mad(.4, d2, 1.);
    float wA = mad(lob, d2, -1.);
    wB *= wB;
    wA *= wA;
    wB = mad(1.5625, wB, .5625);
    float w = wB * wA;
    // Do weighted average.
    aC += c * w;
    aW += w;
}

//------------------------------------------------------------------------------------------------------------------------------
// Accumulate direction and length.
void FsrEasuSetF(
    inout float2 dir,
    inout float len,
    float w,
    float lA, float lB, float lC, float lD, float lE
)
{
    // Direction is the '+' diff.
    //    a
    //  b c d
    //    e
    // Then takes magnitude from abs average of both sides of 'c'.
    // Length converts gradient reversal to 0, smoothly to non-reversal at 1, shaped, then adding horz and vert terms.
    float lenX = max(abs(lD - lC), abs(lC - lB));
    float dirX = lD - lB;
    dir.x += dirX * w;
    lenX = clamp(abs(dirX) / lenX, 0., 1.);
    lenX *= lenX;
    len += lenX * w;
    // Repeat for the y axis.
    float lenY = max(abs(lE - lC), abs(lC - lA));
    float dirY = lE - lA;
    dir.y += dirY * w;
    lenY = clamp(abs(dirY) / lenY, 0., 1.);
    lenY *= lenY;
    len += lenY * w;
}

//------------------------------------------------------------------------------------------------------------------------------
void FsrEasuF(
    out float3 pix,
    float2 ip, // Integer pixel position in output.
    // Constants generated by FsrEasuCon().
    float4 con0, // xy = output to input scale, zw = first pixel offset correction
    float4 con1,
    float4 con2,
    float4 con3
)
{
    //------------------------------------------------------------------------------------------------------------------------------
    // Get position of 'f'.
    float2 pp = mad(ip, con0.xy, con0.zw); // Corresponding input pixel/subpixel
    float2 fp = floor(pp);// fp = source nearest pixel
    pp -= fp; // pp = source subpixel

    //------------------------------------------------------------------------------------------------------------------------------
    // 12-tap kernel.
    //    b c
    //  e f g h
    //  i j k l
    //    n o
    // Gather 4 ordering.
    //  a b
    //  r g
    float2 p0 = mad(fp, con1.xy, con1.zw);

    // These are from p0 to avoid pulling two constants on pre-Navi hardware.
    float2 p1 = p0 + con2.xy;
    float2 p2 = p0 + con2.zw;
    float2 p3 = p0 + con3.xy;

    // TextureGather is not available on WebGL2
    float4 off = float4(-.5, .5, -.5, .5) * con1.xxyy;
    // textureGather to texture offsets
    // x=west y=east z=north w=south
    float3 bC = tex2D(s0, p0 + off.xw).rgb; float bL = mad(0.5, bC.r + bC.b, bC.g);
    float3 cC = tex2D(s0, p0 + off.yw).rgb; float cL = mad(0.5, cC.r + cC.b, cC.g);
    float3 iC = tex2D(s0, p1 + off.xw).rgb; float iL = mad(0.5, iC.r + iC.b, iC.g);
    float3 jC = tex2D(s0, p1 + off.yw).rgb; float jL = mad(0.5, jC.r + jC.b, jC.g);
    float3 fC = tex2D(s0, p1 + off.yz).rgb; float fL = mad(0.5, fC.r + fC.b, fC.g);
    float3 eC = tex2D(s0, p1 + off.xz).rgb; float eL = mad(0.5, eC.r + eC.b, eC.g);
    float3 kC = tex2D(s0, p2 + off.xw).rgb; float kL = mad(0.5, kC.r + kC.b, kC.g);
    float3 lC = tex2D(s0, p2 + off.yw).rgb; float lL = mad(0.5, lC.r + lC.b, lC.g);
    float3 hC = tex2D(s0, p2 + off.yz).rgb; float hL = mad(0.5, hC.r + hC.b, hC.g);
    float3 gC = tex2D(s0, p2 + off.xz).rgb; float gL = mad(0.5, gC.r + gC.b, gC.g);
    float3 oC = tex2D(s0, p3 + off.yz).rgb; float oL = mad(0.5, oC.r + oC.b, oC.g);
    float3 nC = tex2D(s0, p3 + off.xz).rgb; float nL = mad(0.5, nC.r + nC.b, nC.g);

    //------------------------------------------------------------------------------------------------------------------------------
    // Simplest multi-channel approximate luma possible (luma times 2, in 2 FMA/MAD).
    // Accumulate for bilinear interpolation.
    float2 dir = float2(0.0, 0.0);
    float len = 0.;

    FsrEasuSetF(dir, len, (1. - pp.x) * (1. - pp.y), bL, eL, fL, gL, jL);
    FsrEasuSetF(dir, len, pp.x * (1. - pp.y), cL, fL, gL, hL, kL);
    FsrEasuSetF(dir, len, (1. - pp.x) * pp.y, fL, iL, jL, kL, nL);
    FsrEasuSetF(dir, len, pp.x * pp.y, gL, jL, kL, lL, oL);

    //------------------------------------------------------------------------------------------------------------------------------
    // Normalize with approximation, and cleanup close to zero.
    float2 dir2 = dir * dir;
    float dirR = dir2.x + dir2.y;
    bool zro = dirR < (1.0 / 32768.0);
    dirR = rsqrt(dirR);
    dirR = zro ? 1.0 : dirR;
    dir.x = zro ? 1.0 : dir.x;
    dir *= float2(dirR, dirR);
    // Transform from {0 to 2} to {0 to 1} range, and shape with square.
    len = len * 0.5;
    len *= len;
    // Stretch kernel {1.0 vert|horz, to sqrt(2.0) on diagonal}.
    float stretch = dot(dir, dir) / (max(abs(dir.x), abs(dir.y)));
    // Anisotropic length after rotation,
    //  x := 1.0 lerp to 'stretch' on edges
    //  y := 1.0 lerp to 2x on edges
    float2 len2 = float2(mad(stretch - 1.0, len, 1), mad(-.5, len, 1.));
    // Based on the amount of 'edge',
    // the window shifts from +/-{sqrt(2.0) to slightly beyond 2.0}.
    float lob = mad(-.29, len, .5);
    // Set distance^2 clipping point to the end of the adjustable window.
    float clp = 1. / lob;

    //------------------------------------------------------------------------------------------------------------------------------
    // Accumulation mixed with min/max of 4 nearest.
    //    b c
    //  e f g h
    //  i j k l
    //    n o
    float3 min4 = min(min(fC, gC), min(jC, kC));
    float3 max4 = max(max(fC, gC), max(jC, kC));
    // Accumulation.
    float3 aC = float3(0, 0, 0);
    float aW = 0.;
    FsrEasuTapF(aC, aW, float2(0, -1) - pp, dir, len2, lob, clp, bC);
    FsrEasuTapF(aC, aW, float2(1, -1) - pp, dir, len2, lob, clp, cC);
    FsrEasuTapF(aC, aW, float2(-1, 1) - pp, dir, len2, lob, clp, iC);
    FsrEasuTapF(aC, aW, float2(0, 1)  - pp, dir, len2, lob, clp, jC);
    FsrEasuTapF(aC, aW, float2(0, 0)  - pp, dir, len2, lob, clp, fC);
    FsrEasuTapF(aC, aW, float2(-1, 0) - pp, dir, len2, lob, clp, eC);
    FsrEasuTapF(aC, aW, float2(1, 1)  - pp, dir, len2, lob, clp, kC);
    FsrEasuTapF(aC, aW, float2(2, 1)  - pp, dir, len2, lob, clp, lC);
    FsrEasuTapF(aC, aW, float2(2, 0)  - pp, dir, len2, lob, clp, hC);
    FsrEasuTapF(aC, aW, float2(1, 0)  - pp, dir, len2, lob, clp, gC);
    FsrEasuTapF(aC, aW, float2(1, 2)  - pp, dir, len2, lob, clp, oC);
    FsrEasuTapF(aC, aW, float2(0, 2)  - pp, dir, len2, lob, clp, nC);
    //------------------------------------------------------------------------------------------------------------------------------
    // Normalize and dering.
    pix = min(max4, max(min4, aC / aW));
}

float4 BufferA(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float3 c;
    float4 con0, con1, con2, con3;

    // "rendersize" refers to size of source image before upscaling.
    float2 rendersize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    FsrEasuCon(con0, con1, con2, con3, rendersize, rendersize, float2(BUFFER_WIDTH, BUFFER_HEIGHT));
    FsrEasuF(c, texcoord, con0, con1, con2, con3);
    return float4(c.xyz, 1);
}

//---------------------------------------------------------------------- BufferA END / FSR MAIN

#define FSR_RCAS_LIMIT (0.25-(1.0/16.0))

float4 FsrRcasLoadF(float2 p)
{
    return tex2D(BufferASampler, p / float2(3840.0, 2160.0));
}

// The scale is {0.0 := maximum, to N>0, where N is the number of stops (halving) of the reduction of sharpness}.
//----------------------------------------------------------------------------------------------------------------
float FsrRcasCon(float sharpness)
{
    // Transform from stops to linear value.
    return exp2(-sharpness);
}

float3 FsrRcasF(
    float2 ip, // Integer pixel position in output.
    float con
)
{
    // Constant generated by RcasSetup().
    // Algorithm uses minimal 3x3 pixel neighborhood.
    //    b 
    //  d e f
    //    h
    float2 sp = float2(ip);
    float3 b = FsrRcasLoadF(sp + float2(0, -1)).rgb;
    float3 d = FsrRcasLoadF(sp + float2(-1, 0)).rgb;
    float3 e = FsrRcasLoadF(sp).rgb;
    float3 f = FsrRcasLoadF(sp + float2(1, 0)).rgb;
    float3 h = FsrRcasLoadF(sp + float2(0, 1)).rgb;

    // Luma times 2.
    float bL = mad(.5, b.b + b.r, b.g);
    float dL = mad(.5, d.b + d.r, d.g);
    float eL = mad(.5, e.b + e.r, e.g);
    float fL = mad(.5, f.b + f.r, f.g);
    float hL = mad(.5, h.b + h.r, h.g);

    // Noise detection.
    float nz = mad(.25, bL + dL + fL + hL, -eL);
    nz = clamp(abs(nz) / (max(max(bL, dL), max(eL, max(fL, hL))) - min(min(bL, dL), min(eL, min(fL, hL)))), 0., 1.);
    nz = mad(-.5, nz, 1.);
    // Min and max of ring.
    float3 mn4 = min(b, min(f, h));
    float3 mx4 = max(b, max(f, h));
    // Immediate constants for peak range.
    float2 peakC = float2(1., -4.);
    // Limiters, these need to be high precision RCPs.
    float3 hitMin = mn4 / (4. * mx4);
    float3 hitMax = (peakC.x - mx4) / mad(4., mn4, peakC.y);
    float3 lobeRGB = max(-hitMin, hitMax);
    float lobe = max(-FSR_RCAS_LIMIT, min(max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b)), 0.)) * con;

    // Resolve, which needs the medium precision rcp approximation to avoid visible tonality changes.
    return mad(lobe, b + d + h + f, e) / mad(4., lobe, 1.);
}

float4 FSR(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Set up constants
    float sharpness = 0.2;
    float con = FsrRcasCon(sharpness);

    // Perform RCAS pass
    float3 col = FsrRcasF(texcoord, con);

    return float4(col, 1.0);
}

// For testing / debugging
float4 BasicPS(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return tex2D(s0, texcoord);
}

float4 BasicPS2(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return tex2D(BufferASampler, texcoord);
}

technique FSRTechnique < enabled = true; >
{
	pass BufferAPass
	{
		VertexShader = FullscreenTriangle;
		//PixelShader  = BufferA; // maybe recursion?
        PixelShader = BasicPS;
		RenderTarget = BufferATex;
	}

	pass SuperResPass
	{
		VertexShader = FullscreenTriangle;
		//PixelShader  = FSR;
        PixelShader = BasicPS2;
	}
}

#endif
