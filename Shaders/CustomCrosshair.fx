#include "ReShadeUI.fxh"
#include "ReShade.fxh"

// ------------------------------------------------------------------------------------------------------------------------
// Crosshair Offset
// ------------------------------------------------------------------------------------------------------------------------

    uniform int ConfigNotice <
        ui_type = "radio";
        ui_label = " ";
        ui_text = "- Requires [CustomCrosshairSetup.fx]\n"
                  "- Enable CustomCrosshairSetup to change shape and color.\n"
                  "- Enable CustomCrosshairUIDetectGUI to automatically show/hide crosshair (requires [UIDetectGUI.fx]).\n"
                  "- CustomCrosshairSetup may be disabled for performance.";
    >;

    uniform float2 Offset <
        ui_type = "drag";
        ui_min = BUFFER_SCREEN_SIZE / -2.0;
        ui_max = BUFFER_SCREEN_SIZE / 2.0;
        ui_step = 1.0;
        ui_label = "Offset";
        ui_tooltip = "Horizontal and vertical offset for the crosshair relative to the window center.";
    > = float2(0.0, 0.0);

    uniform bool FollowCursor <
        ui_label = "Follow Cursor";
        ui_tooltip = "Apply crosshair relative to mouse cursor instead of the window center.";
    > = false;

// ------------------------------------------------------------------------------------------------------------------------
// Hotkeys
// ------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------
// Hotkey 1
// ------------------------------------------------------------------------------------------------------------------------

    uniform bool Hotkey1 <
        ui_label = "Hotkey 1";
        ui_category = "Hotkey 1";
        ui_category_closed = true;
    > = false;

    uniform int HotkeyBehavior1 <
        ui_type = "combo";
        ui_label = "Behavior";
        ui_items = "Hold Hide\0Hold Show\0Toggle\0Hide\0Show\0";
        ui_tooltip = "Hold Hide: Hide the crosshair when held.\n"
                        "Hold Show: Show the crosshair when held and not toggled.\n"
                        "Toggle: Show the crosshair if toggled. Hide if not toggled.\n"
                        "Hide: Toggle to hide the crosshair if not toggled.\n"
                        "Show: Toggle to show the crosshair if toggled.";
        ui_category = "Hotkey 1";
        ui_category_closed = true;
    > = 0;

    uniform int HotkeyButton1 <
        ui_type = "combo";
        ui_label = "Button";
        ui_items = "Left-Click\0Right-Click\0Middle-Click\0Back-Click\0Forward-Click\0 1\0 2\0 3\0 4\0 5\0WASD\0Shift\0Ctrl\0Alt\0Spacebar\0Custom Hotkey 1\0Custom Hotkey 2\0Custom Hotkey 3\0";
        ui_category = "Hotkey 1";
        ui_category_closed = true;
    > = 1;

// ------------------------------------------------------------------------------------------------------------------------
// Hotkey 2
// ------------------------------------------------------------------------------------------------------------------------

    uniform bool Hotkey2 <
        ui_label = "Hotkey 2";
        ui_category = "Hotkey 2";
        ui_category_closed = true;
    > = false;

    uniform int HotkeyBehavior2 <
        ui_type = "combo";
        ui_label = "Behavior";
        ui_items = "Hold Hide\0Hold Show\0Toggle\0Hide\0Show\0";
        ui_tooltip = "Hold Hide: Hide the crosshair when held.\n"
                        "Hold Show: Show the crosshair when held and not toggled.\n"
                        "Toggle: Show the crosshair if toggled. Hide if not toggled.\n"
                        "Hide: Toggle to hide the crosshair if not toggled.\n"
                        "Show: Toggle to show the crosshair if toggled.";
        ui_category = "Hotkey 2";
        ui_category_closed = true;
    > = 0;

    uniform int HotkeyButton2 <
        ui_type = "combo";
        ui_label = "Button";
        ui_items = "Left-Click\0Right-Click\0Middle-Click\0Back-Click\0Forward-Click\0 1\0 2\0 3\0 4\0 5\0WASD\0Shift\0Ctrl\0Alt\0Spacebar\0Custom Hotkey 1\0Custom Hotkey 2\0Custom Hotkey 3\0";
        ui_category = "Hotkey 2";
        ui_category_closed = true;
    > = 1;

// ------------------------------------------------------------------------------------------------------------------------
// Hotkey 3
// ------------------------------------------------------------------------------------------------------------------------

    uniform bool Hotkey3 <
        ui_label = "Hotkey 3";
        ui_category = "Hotkey 3";
        ui_category_closed = true;
    > = false;

    uniform int HotkeyBehavior3 <
        ui_type = "combo";
        ui_label = "Behavior";
        ui_items = "Hold Hide\0Hold Show\0Toggle\0Hide\0Show\0";
        ui_tooltip = "Hold Hide: Hide the crosshair when held.\n"
                        "Hold Show: Show the crosshair when held and not toggled.\n"
                        "Toggle: Show the crosshair if toggled. Hide if not toggled.\n"
                        "Hide: Toggle to hide the crosshair if not toggled.\n"
                        "Show: Toggle to show the crosshair if toggled.";
        ui_category = "Hotkey 3";
        ui_category_closed = true;
    > = 0;

    uniform int HotkeyButton3 <
        ui_type = "combo";
        ui_label = "Button";
        ui_items = "Left-Click\0Right-Click\0Middle-Click\0Back-Click\0Forward-Click\0 1\0 2\0 3\0 4\0 5\0WASD\0Shift\0Ctrl\0Alt\0Spacebar\0Custom Hotkey 1\0Custom Hotkey 2\0Custom Hotkey 3\0";
        ui_category = "Hotkey 3";
        ui_category_closed = true;
    > = 1;

// ------------------------------------------------------------------------------------------------------------------------
// Variables
// ------------------------------------------------------------------------------------------------------------------------

    static const float2 CenterPoint = BUFFER_SCREEN_SIZE / 2.0;
    static const float2 PixelOffset = float2(0.5, 0.5);
    static const float2 anchorOffsets[9] = {float2(0.5, 0.5), float2(0.0, 0.5), float2(-0.5, 0.5), float2(0.5, 0.0), float2(0.0, 0.0), float2(-0.5, 0.0), float2(0.5, -0.5), float2(0.0, -0.5), float2(-0.5, -0.5)};
    
    uniform float2 MousePoint < source = "mousepoint"; >;
    
    uniform bool MouseLeft_Down < source = "mousebutton"; keycode = 0; mode = ""; >;
    uniform bool MouseLeft_Press < source = "mousebutton"; keycode = 0; mode = "press"; >;
    uniform bool MouseRight_Down < source = "mousebutton"; keycode = 1; mode = ""; >;
    uniform bool MouseRight_Press < source = "mousebutton"; keycode = 1; mode = "press"; >;
    uniform bool MouseMiddle_Down < source = "mousebutton"; keycode = 2; mode = ""; >;
    uniform bool MouseMiddle_Press < source = "mousebutton"; keycode = 2; mode = "press"; >;
    uniform bool MouseBack_Down < source = "mousebutton"; keycode = 3; mode = ""; >;
    uniform bool MouseBack_Press < source = "mousebutton"; keycode = 3; mode = "press"; >;
    uniform bool MouseForward_Down < source = "mousebutton"; keycode = 4; mode = ""; >;
    uniform bool MouseForward_Press < source = "mousebutton"; keycode = 4; mode = "press"; >;

    uniform bool Spacebar_Down <source = "key"; keycode = 0x20; mode = ""; >;
    uniform bool Spacebar_Press <source = "key"; keycode = 0x20; mode = "press"; >;
    uniform bool Shift_Down <source = "key"; keycode = 0x10; mode = ""; >;
    uniform bool Shift_Press <source = "key"; keycode = 0x10; mode = "press"; >;
    uniform bool Ctrl_Down <source = "key"; keycode = 0x11; mode = ""; >;
    uniform bool Ctrl_Press <source = "key"; keycode = 0x11; mode = "press"; >;
    uniform bool Alt_Down <source = "key"; keycode = 0x12; mode = ""; >;
    uniform bool Alt_Press <source = "key"; keycode = 0x12; mode = "press"; >;
    
    uniform bool One_Down <source = "key"; keycode = 0x31; mode = ""; >;
    uniform bool One_Press <source = "key"; keycode = 0x31; mode = "press"; >;
    uniform bool Two_Down <source = "key"; keycode = 0x32; mode = ""; >;
    uniform bool Two_Press <source = "key"; keycode = 0x32; mode = "press"; >;
    uniform bool Three_Down <source = "key"; keycode = 0x33; mode = ""; >;
    uniform bool Three_Press <source = "key"; keycode = 0x33; mode = "press"; >;
    uniform bool Four_Down <source = "key"; keycode = 0x34; mode = ""; >;
    uniform bool Four_Press <source = "key"; keycode = 0x34; mode = "press"; >;
    uniform bool Five_Down <source = "key"; keycode = 0x35; mode = ""; >;
    uniform bool Five_Press <source = "key"; keycode = 0x35; mode = "press"; >;
    
    uniform bool WWW_Down <source = "key"; keycode = 0x57; mode = ""; >;
    uniform bool WWW_Press <source = "key"; keycode = 0x57; mode = "press"; >;
    uniform bool AAA_Down <source = "key"; keycode = 0x41; mode = ""; >;
    uniform bool AAA_Press <source = "key"; keycode = 0x41; mode = "press"; >;
    uniform bool SSS_Down <source = "key"; keycode = 0x53; mode = ""; >;
    uniform bool SSS_Press <source = "key"; keycode = 0x53; mode = "press"; >;
    uniform bool DDD_Down <source = "key"; keycode = 0x44; mode = ""; >;
    uniform bool DDD_Press <source = "key"; keycode = 0x44; mode = "press"; >;

    #ifndef CUSTOM_HOTKEY_KEYCODE_1
        #define CUSTOM_HOTKEY_KEYCODE_1 0x51
    #endif

    #ifndef CUSTOM_HOTKEY_KEYCODE_2
        #define CUSTOM_HOTKEY_KEYCODE_2 0x45
    #endif

    #ifndef CUSTOM_HOTKEY_KEYCODE_3
        #define CUSTOM_HOTKEY_KEYCODE_3 0x52
    #endif

    uniform bool CustomKey1_Down <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_1; mode = ""; >;
    uniform bool CustomKey1_Press <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_1; mode = "press"; >;
    uniform bool CustomKey2_Down <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_2; mode = ""; >;
    uniform bool CustomKey2_Press <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_2; mode = "press"; >;
    uniform bool CustomKey3_Down <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_3; mode = ""; >;
    uniform bool CustomKey3_Press <source = "key"; keycode = CUSTOM_HOTKEY_KEYCODE_3; mode = "press"; >;

    /*
    To Do:
    - option to use png image layer instead of shape - see https://github.com/CeeJayDK/SweetFX/blob/master/Shaders/Layer.fx
    - hotkey animated transformations - likely too expensive unless pre-rendered - could use overlay LoD for frames?
    */

// ------------------------------------------------------------------------------------------------------------------------
// Textures
// ------------------------------------------------------------------------------------------------------------------------

    texture2D CustomCrosshairStateTex <pooled = false; > { Width = 3; Height = 1; Format = R8; };
    sampler2D CustomCrosshairStateSamp { Texture = CustomCrosshairStateTex; };

    texture2D CustomCrosshairPrevStateTex <pooled = false; > { Width = 3; Height = 1; Format = R8; };
    sampler2D CustomCrosshairPrevStateSamp { Texture = CustomCrosshairPrevStateTex; };

    texture2D CustomCrosshairBoundingBoxTexture < pooled = false; > { Width = 4; Height = 1; Format = R32F; };
    sampler2D CustomCrosshairBoundingBoxSampler { Texture = CustomCrosshairBoundingBoxTexture; };

    texture2D UIDetectCustomCrosshairTexture <pooled = false; > { Width = 1; Height = 1; Format = R8; };
    sampler2D UIDetectCustomCrosshairSampler { Texture = UIDetectCustomCrosshairTexture; };

    texture2D CustomCrosshairOverlayTexture <pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler2D CustomCrosshairOverlaySampler { Texture = CustomCrosshairOverlayTexture;};

// ------------------------------------------------------------------------------------------------------------------------
// Structs
// ------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------
// Functions
// ------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------------------------
// Pixel Shaders
// ------------------------------------------------------------------------------------------------------------------------

    float PS_PrevStateHandler(float4 pos: SV_POSITION, float2 texCoord: TEXCOORD) : SV_TARGET {
        return tex2Dfetch(CustomCrosshairStateSamp, floor(pos.xy), 0).r;
    }

    float PS_StateHandler(float4 pos: SV_POSITION, float2 texCoord: TEXCOORD) : SV_TARGET {
        const int pixelNumber = floor(pos.x);
        if (Hotkey1 || Hotkey2 || Hotkey3) {
            const bool hotkeyDown[18] = { MouseLeft_Down, MouseRight_Down, MouseMiddle_Down, MouseBack_Down, MouseForward_Down, One_Down, Two_Down, Three_Down, Four_Down, Five_Down, WWW_Down || AAA_Down || SSS_Down || DDD_Down, Shift_Down, Ctrl_Down, Alt_Down, Spacebar_Down, CustomKey1_Down, CustomKey2_Down, CustomKey3_Down };
            const bool hotkeyPress[18] = { MouseLeft_Press, MouseRight_Press, MouseMiddle_Press, MouseBack_Press, MouseForward_Press, One_Press, Two_Press, Three_Press, Four_Press, Five_Press, WWW_Press || AAA_Press || SSS_Press || DDD_Press, Shift_Press, Ctrl_Press, Alt_Press, Spacebar_Press, CustomKey1_Press, CustomKey2_Press, CustomKey3_Press };
            const bool hotkeyTriggered1 = Hotkey1 && (tex2Dfetch(CustomCrosshairPrevStateSamp, int2(0, 0), 0).r > 0.0);
            const bool hotkeyTriggered2 = Hotkey2 && (tex2Dfetch(CustomCrosshairPrevStateSamp, int2(1, 0), 0).r > 0.0);
            const bool hotkeyTriggered3 = Hotkey3 && (tex2Dfetch(CustomCrosshairPrevStateSamp, int2(2, 0), 0).r > 0.0);

            bool toggled = (HotkeyBehavior1 > 1) && hotkeyTriggered1 || (HotkeyBehavior2 > 1) && hotkeyTriggered2 || (HotkeyBehavior3 > 1) && hotkeyTriggered3;

            if (pixelNumber == 0 && Hotkey1) {
                if (Hotkey2 && HotkeyBehavior2 == 2 && hotkeyPress[HotkeyButton2] && toggled) toggled = false;
                if (Hotkey2 && HotkeyBehavior2 == 4 && hotkeyPress[HotkeyButton2]) toggled = false;
                if (Hotkey3 && HotkeyBehavior3 == 2 && hotkeyPress[HotkeyButton3] && toggled) toggled = false;
                if (Hotkey3 && HotkeyBehavior3 == 4 && hotkeyPress[HotkeyButton3]) toggled = false;

                if (HotkeyBehavior1 == 0 && hotkeyDown[HotkeyButton1]) return 1.0;
                if (HotkeyBehavior1 == 0 && !hotkeyDown[HotkeyButton1] && !toggled) return 0.0;
                if (HotkeyBehavior1 == 1 && !hotkeyDown[HotkeyButton1]) return 1.0;
                if (HotkeyBehavior1 == 1 && hotkeyDown[HotkeyButton1] && !toggled) return 0.0;
                if (HotkeyBehavior1 == 2 && hotkeyPress[HotkeyButton1] && !toggled) return 1.0;
                if (HotkeyBehavior1 == 2 && hotkeyPress[HotkeyButton1] && toggled) return 0.0;
                if (HotkeyBehavior1 == 3 && hotkeyPress[HotkeyButton1]) return 1.0;
                if (HotkeyBehavior1 == 4 && hotkeyPress[HotkeyButton1]) return 0.0;
                if (HotkeyBehavior1 > 1) return (toggled ? 1.0 : 0.0);
                return (hotkeyTriggered1 ? 1.0 : 0.0);
            }
            if (pixelNumber == 1 && Hotkey2) {
                if (Hotkey1 && HotkeyBehavior1 == 2 && hotkeyPress[HotkeyButton1] && toggled) toggled = false;
                if (Hotkey1 && HotkeyBehavior1 == 4 && hotkeyPress[HotkeyButton1]) toggled = false;
                if (Hotkey3 && HotkeyBehavior3 == 2 && hotkeyPress[HotkeyButton3] && toggled) toggled = false;
                if (Hotkey3 && HotkeyBehavior3 == 4 && hotkeyPress[HotkeyButton3]) toggled = false;

                if (HotkeyBehavior2 == 0 && hotkeyDown[HotkeyButton2]) return 1.0;
                if (HotkeyBehavior2 == 0 && !hotkeyDown[HotkeyButton2] && !toggled) return 0.0;
                if (HotkeyBehavior2 == 1 && !hotkeyDown[HotkeyButton2]) return 1.0;
                if (HotkeyBehavior2 == 1 && hotkeyDown[HotkeyButton2] && !toggled) return 0.0;
                if (HotkeyBehavior2 == 2 && hotkeyPress[HotkeyButton2] && !toggled) return 1.0;
                if (HotkeyBehavior2 == 2 && hotkeyPress[HotkeyButton2] && toggled) return 0.0;
                if (HotkeyBehavior2 == 3 && hotkeyPress[HotkeyButton2]) return 1.0;
                if (HotkeyBehavior2 == 4 && hotkeyPress[HotkeyButton2]) return 0.0;
                if (HotkeyBehavior2 > 1) return (toggled ? 1.0 : 0.0);
                return (hotkeyTriggered2 ? 1.0 : 0.0);
            }
            if (pixelNumber == 2 && Hotkey3) {
                if (Hotkey2 && HotkeyBehavior2 == 2 && hotkeyPress[HotkeyButton2] && toggled) toggled = false;
                if (Hotkey2 && HotkeyBehavior2 == 4 && hotkeyPress[HotkeyButton2]) toggled = false;
                if (Hotkey1 && HotkeyBehavior1 == 2 && hotkeyPress[HotkeyButton1] && toggled) toggled = false;
                if (Hotkey1 && HotkeyBehavior1 == 4 && hotkeyPress[HotkeyButton1]) toggled = false;

                if (HotkeyBehavior3 == 0 && hotkeyDown[HotkeyButton3]) return 1.0;
                if (HotkeyBehavior3 == 0 && !hotkeyDown[HotkeyButton3] && !toggled) return 0.0;
                if (HotkeyBehavior3 == 1 && !hotkeyDown[HotkeyButton3]) return 1.0;
                if (HotkeyBehavior3 == 1 && hotkeyDown[HotkeyButton3] && !toggled) return 0.0;
                if (HotkeyBehavior3 == 2 && hotkeyPress[HotkeyButton3] && !toggled) return 1.0;
                if (HotkeyBehavior3 == 2 && hotkeyPress[HotkeyButton3] && toggled) return 0.0;
                if (HotkeyBehavior3 == 3 && hotkeyPress[HotkeyButton3]) return 1.0;
                if (HotkeyBehavior3 == 4 && hotkeyPress[HotkeyButton3]) return 0.0;
                if (HotkeyBehavior3 > 1) return (toggled ? 1.0 : 0.0);
                return (hotkeyTriggered3 ? 1.0 : 0.0);
            }
        }
        return 0.0;
    }

    void VS_Final(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
    {
        const bool uiDetected = tex2Dfetch(UIDetectCustomCrosshairSampler, int2(0, 0), 0).r > 0.0;
        const bool hotkeyTriggered1 = Hotkey1 && (tex2Dfetch(CustomCrosshairStateSamp, int2(0, 0), 0).r > 0.0);
        const bool hotkeyTriggered2 = Hotkey2 && (tex2Dfetch(CustomCrosshairStateSamp, int2(1, 0), 0).r > 0.0);
        const bool hotkeyTriggered3 = Hotkey3 && (tex2Dfetch(CustomCrosshairStateSamp, int2(2, 0), 0).r > 0.0);
        
        if (uiDetected || hotkeyTriggered1 || hotkeyTriggered2 || hotkeyTriggered3)
            PostProcessVS(0, position, texcoord);
        else {
            const float2 overlayOffset = (Offset + (FollowCursor ? MousePoint - CenterPoint : 0)) / BUFFER_SCREEN_SIZE;
            texcoord.x = (id < 2) ? tex2Dfetch(CustomCrosshairBoundingBoxSampler, int2(0, 0), 0).r : tex2Dfetch(CustomCrosshairBoundingBoxSampler, int2(2, 0), 0).r;
            texcoord.y = (id == 0 || id == 2) ? tex2Dfetch(CustomCrosshairBoundingBoxSampler, int2(1, 0), 0).r : tex2Dfetch(CustomCrosshairBoundingBoxSampler, int2(3, 0), 0).r;
            texcoord.xy += overlayOffset;
            position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
        }
    }

    float4 PS_Final(float4 pos: SV_POSITION, float2 texCoord: TEXCOORD) : SV_TARGET {
        const float2 overlayOffset = Offset + (FollowCursor ? MousePoint - CenterPoint : 0);
        const float4 overlay = tex2Dlod(CustomCrosshairOverlaySampler, float4(texCoord - overlayOffset * BUFFER_PIXEL_SIZE, 0, 0));
        if (overlay.a > 0.0) return overlay;

        discard;
    }

// ------------------------------------------------------------------------------------------------------------------------
// Techniques
// ------------------------------------------------------------------------------------------------------------------------

    technique CustomCrosshair <
        ui_label = "CustomCrosshair";
        ui_tooltip = "Requires [CustomCrosshairSetup.fx]\n"
                     "Enable to show a crosshair overlay on the screen.\n"
                     "Enable CustomCrosshairSetup to change shape and color.\n"
                     "Enable CustomCrosshairUIDetectGUI detect UI to show/hide crosshair (requires [UIDetectGUI.fx]).\n";
    > {
        pass prevState {
            VertexShader = PostProcessVS;
            PixelShader = PS_PrevStateHandler;
            RenderTarget = CustomCrosshairPrevStateTex;
        }
        pass state {
            VertexShader = PostProcessVS;
            PixelShader = PS_StateHandler;
            RenderTarget = CustomCrosshairStateTex;
        }
        pass final {
            PrimitiveTopology = TRIANGLESTRIP;
            VertexCount = 4;
            VertexShader = VS_Final;
            PixelShader = PS_Final;
            BlendEnable = true;
            SrcBlend = SRCALPHA;
            DestBlend = INVSRCALPHA;
        }
    }
