-- This file is part of RedyCode™ Integrated Development Environment
-- <http://redy-project.org/>
-- 
-- Copyright 2016 Ryan W. Johnson
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--   http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-------------------------------------------------------------------------------



include redylib_0_9/oswin.e as oswin

global atom

scrwidth,

--outer area
cOuterFill,
cOuterActive,
cOuterHover,
cOuterLabel,
cOuterHighlight,

--3D objects 
cButtonDark,
cButtonFace,
cButtonActive,
cButtonHover,
cButtonHighlight,
cButtonShadow,
cButtonLabel,
cButtonDisLabel,
               
--Inner        
cInnerDark,

cInnerShape,

cInnerFill,
cInnerText,

cInnerHover,
cInnerTextHover,
      
cInnerSel,
cInnerTextSel,

cInnerSelHover,
cInnerTextSelHover,

cInnerSelInact,
cInnerTextSelInact,
  
--Items inside lists
cInnerItemOdd,
cInnerItemEven,
cInnerItemText,

cInnerItemOddHover,
cInnerItemEvenHover,
cInnerItemTextHover,

cInnerItemOddSel,
cInnerItemEvenSel,
cInnerItemTextSel,

cInnerItemOddSelHover,
cInnerItemEvenSelHover,
cInnerItemTextSelHover,

cInnerItemOddSelInact,
cInnerItemEvenSelInact,
cInnerItemTextSelInact


--These Windows system colors might be useful for making a theme
--# COLOR_SCROLLBAR
--# COLOR_BACKGROUND
--# COLOR_DESKTOP
--# COLOR_ACTIVECAPTION
--# COLOR_INACTIVECAPTION
--# COLOR_MENU
--# COLOR_WINDOW
--# COLOR_WINDOWFRAME
--# COLOR_MENUTEXT
--# COLOR_WINDOWTEXT
--# COLOR_CAPTIONTEXT
--# COLOR_ACTIVEBORDER
--# COLOR_INACTIVEBORDER
--# COLOR_APPWORKSPACE
--# COLOR_HIGHLIGHT
--# COLOR_HIGHLIGHTTEXT
--# COLOR_BTNFACE
--# COLOR_BTNSHADOW
--# COLOR_GRAYTEXT
--# COLOR_BTNTEXT
--# COLOR_INACTIVECAPTIONTEXT
--# COLOR_BTNHIGHLIGHT
--# COLOR_3DDKSHADOW
--# COLOR_3DLIGHT
--# COLOR_INFOTEXT
--# COLOR_INFOBK
--# COLOR_HOTLIGHT
--# COLOR_GRADIENTACTIVECAPTION
--# COLOR_GRADIENTINACTIVECAPTION
--# COLOR_MENUHILIGHT
--# COLOR_MENUBAR

    scrwidth = 16

    --outer area
    cOuterFill             = rgb(212, 208, 200)
    cOuterActive           = rgb(190, 208, 228)
    cOuterHover            = rgb(212, 208, 200)
    cOuterLabel            = rgb(0, 0, 0)
    cOuterHighlight        = rgb(190, 208, 228) --rgb(186, 231,255)
    
    --3D objects  
    cButtonDark            = rgb(200, 196, 188)
    cButtonFace            = rgb(220, 216, 208)
    cButtonActive          = rgb(181, 217, 255)
    cButtonHover           = rgb(166, 202, 240)
    cButtonHighlight       = rgb(255, 255, 255)
    cButtonShadow          = rgb(171, 171, 171)
    cButtonLabel           = rgb(0, 0, 0)
    cButtonDisLabel        = rgb(127, 127, 127)
                          
    --Inner          
    cInnerDark             = rgb(20, 20, 20)
    
    cInnerShape            = rgb(10, 36, 106)  --139,174,217) 
    
    cInnerFill             = rgb(252, 252, 252)
    cInnerText             = rgb(0, 0, 0)
    
    cInnerHover            = rgb(225, 245, 255)
    cInnerTextHover        = rgb(0, 0, 0)
          
    cInnerSel              = rgb(166, 202, 240)
    cInnerTextSel          = rgb(0, 0, 0)
    
    cInnerSelHover         = rgb(166, 202, 240)
    cInnerTextSelHover     = rgb(0, 0, 0)
    
    cInnerSelInact         = rgb(220, 216, 208)
    cInnerTextSelInact     = rgb(0, 0, 0)
      
    --Items inside lists     
    cInnerItemOdd          = rgb(252, 252, 252)
    cInnerItemEven         = rgb(252, 252, 252)
    cInnerItemText         = rgb(0, 0, 0)
    
    cInnerItemOddHover     = rgb(225, 245, 255)
    cInnerItemEvenHover    = rgb(225, 245, 255)
    cInnerItemTextHover    = rgb(0, 0, 0)
    
    cInnerItemOddSel       = rgb(166, 202, 240)
    cInnerItemEvenSel      = rgb(166, 202, 240)
    cInnerItemTextSel      = rgb(0, 0, 0)
    
    cInnerItemOddSelHover  = rgb(166, 202, 240)
    cInnerItemEvenSelHover = rgb(166, 202, 240)   
    cInnerItemTextSelHover = rgb(0, 0, 0)
    
    cInnerItemOddSelInact  = rgb(220, 216, 208)    
    cInnerItemEvenSelInact = rgb(220, 216, 208)     
    cInnerItemTextSelInact = rgb(0, 0, 0)
    

global procedure load_default_theme()
end procedure


