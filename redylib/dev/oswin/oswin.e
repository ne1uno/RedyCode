-- This file is part of redylib
-- <http://redy-project.org/>
-- 
-- Copyright 2015 Ryan W. Johnson
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


--OS Window - Cross-platform Window and Graphics library for Redy Application Environment

--public include themes.e

global atom mArrow, mArrowBusy, mIbeam, mBusy, mNo, mNS, mEW, mNWSE, mNESW, mCrosshair, mNone, mSleeping, mLink

global procedure load_mouse_cursors()
    mArrow = createMousePointer(0, 0, {
              "xx                                ",
              "x.xx                              ",
              " x..xx                            ",
              " x....xx                          ",
              "  x.....xx                        ",
              "  x.......xx                      ",
              "   x........xx                    ",
              "   x..........xx                  ",
              "    x.........x                   ",
              "    x........x                    ",
              "     x........x                   ",
              "     x.........x                  ",
              "      x.......x                   ",
              "      x..x...x                    ",
              "       xx x.x                     ",
              "       x   x                      ",
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  "})
    
    mArrowBusy = createMousePointer(0, 0, {
              "xx                                ",
              "x.xx                              ",
              " x..xx                            ",
              " x....xx                          ",
              "  x.....xx                        ",
              "  x.......xx                      ",
              "   x........xx                    ",
              "   x..........xx                  ",
              "    x.........x                   ",
              "    x........x                    ",
              "     x........x                   ",
              "     x.........x  xxxxx           ",
              "      x.......x xx.....xx         ",
              "      x..x...x x....x....x        ",
              "       xx x.x x.....x.....x       ",
              "       x   x x......x......x      ",
              "             x......x......x      ",
              "            x.......x.......x     ",
              "            x.......x.......x     ",
              "            x.x....x.x....x.x     ",
              "            x.......xx......x     ",
              "            x.........x.....x     ",
              "             x.........x...x      ",  
              "             x.............x      ",  
              "              x...........x       ",  
              "               x....x....x        ",  
              "                xx.....xx         ",  
              "                  xxxxx           "})
              
              
              
    
    mIbeam = createMousePointer(16, 10, {
              "                                  ",
              "                                  ",
              "                                  ",
              "              xx.xx               ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "               x.x                ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "                x                 ",
              "              xx.xx               ",
              "                                  ",
              "                                  ",
              "                                  "})
              
    mBusy = createMousePointer(10, 10, {
              "                                  ",
              "                                  ",
              "        xxxxx                     ",
              "      xx.....xx                   ",
              "     x....x....x                  ",
              "    x.....x.....x                 ",
              "   x......x......x                ",
              "   x......x......x                ",
              "  x.......x.......x               ",
              "  x.......x.......x               ",
              "  x.x....x.x....x.x               ",
              "  x.......xx......x               ",
              "  x.........x.....x               ",
              "   x.........x...x                ",
              "   x.............x                ",
              "    x...........x                 ",
              "     x....x....x                  ",
              "      xx.....xx                   ",
              "        xxxxx                     ",
              "                                  ",
              "                                  "})
    
    mNo = createMousePointer(10, 10, {
              "                                  ",
              "                                  ",
              "        xxxxx                     ",
              "      xx.....xx                   ",
              "     x.........x                  ",
              "    x...xxxxx...x                 ",
              "   x...x    x....x                ",
              "   x..x    x.....x                ",
              "  x..x    x...xx..x               ",
              "  x..x   x...x x..x               ",
              "  x..x  x...x  x..x               ",
              "  x..x x...x   x..x               ",
              "  x..xx...x    x..x               ",
              "   x.....x    x..x                ",
              "   x....x    x...x                ",
              "    x...xxxxx...x                 ",
              "     x.........x                  ",
              "      xx.....xx                   ",
              "        xxxxx                     ",
              "                                  ",
              "                                  "})
    
    mNS = createMousePointer(10, 10, {
              "                                  ",
              "          x                       ",
              "         x.x                      ",
              "        x...x                     ",
              "       x.....x                    ",
              "      x.......x                   ",
              "     xxxxx.xxxxx                  ",
              "         x.x                      ",
              "         x.x                      ",
              "         x.x                      ",
              "         x.x                      ",
              "         x.x                      ",
              "         x.x                      ",
              "         x.x                      ",
              "     xxxxx.xxxxx                  ",
              "      x.......x                   ",
              "       x.....x                    ",
              "        x...x                     ",
              "         x.x                      ",
              "          x                       ",
              "                                  "})
    
    mEW = createMousePointer(10, 10, {
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  ",
              "      x       x                   ",
              "     xx       xx                  ",
              "    x.x       x.x                 ",
              "   x..x       x..x                ",
              "  x...xxxxxxxxx...x               ",
              " x.................x              ",
              "  x...xxxxxxxxx...x               ",
              "   x..x       x..x                ",
              "    x.x       x.x                 ",
              "     xx       xx                  ",
              "      x       x                   ",
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  ",
              "                                  "})
    
    mNWSE = createMousePointer(10, 10, {
              "                                  ",
              "                                  ",
              "                                  ",
              "          xxxxxxxx                ",
              "           x.....x                ",
              "            x....x                ",
              "             x...x                ",
              "            x.x..x                ",
              "           x.x x.x                ",
              "          x.x   xx                ",
              "   x     x.x     x                ",
              "   xx   x.x                       ",
              "   x.x x.x                        ",
              "   x..x.x                         ",
              "   x...x                          ",
              "   x....x                         ",
              "   x.....x                        ",
              "   xxxxxxxx                       ",
              "                                  ",
              "                                  ",
              "                                  "})
    
    mNESW = createMousePointer(10, 10, {
              "                                  ",
              "                                  ",
              "                                  ",
              "   xxxxxxxx                       ",
              "   x.....x                        ",
              "   x....x                         ",
              "   x...x                          ",
              "   x..x.x                         ",
              "   x.x x.x                        ",
              "   xx   x.x                       ",
              "   x     x.x     x                ",
              "          x.x   xx                ",
              "           x.x x.x                ",
              "            x.x..x                ",
              "             x...x                ",
              "            x....x                ",
              "           x.....x                ",
              "          xxxxxxxx                ",
              "                                  ",
              "                                  ",
              "                                  "})
    
    mCrosshair = createMousePointer(15, 15, {
              "              x x                 ",
              "              .x.                 ",
              "               x                  ",
              "               .                  ",
              "               .                  ",
              "               x                  ",
              "               x                  ",
              "               .                  ",
              "               .                  ",
              "               x                  ",
              "               x                  ",
              "               .                  ",
              "               .                  ",
              "                                  ",
              "x.                           .x   ",
              " xx..xx..xx..     ..xx..xx..xx    ",
              "x.                           .x   ",
              "                                  ",
              "               .                  ",
              "               .                  ",
              "               x                  ",
              "               x                  ",
              "               .                  ",
              "               .                  ",
              "               x                  ",
              "               x                  ",
              "               .                  ",
              "               .                  ",
              "               x                  ",
              "              .x.                 ",
              "              x x                 "})
    
    mNone = createMousePointer(1, 1, {" "} )
    
    mSleeping = createMousePointer(4, 2, {
              "                                  ",
              "   xxxxxxxxxxxx                   ",
              "   x..........x                   ",
              "   xxxxxxxx..x                    ",
              "         x..x                     ",
              "        x..x                      ",
              "       x..x                       ",
              "      x..x                        ",
              "     x..x       xxxxxxxxxxxx      ",
              "    x..xxxxxxxx x..........x      ",
              "   x..........x xxxxxxxx..x       ",
              "   xxxxxxxxxxxx       x..x        ",
              "                     x..x         ",
              "                    x..x          ",
              "                   x..x           ",
              "                  x..x            ",
              "                 x..xxxxxxxx      ",
              "                x..........x      ",
              "                xxxxxxxxxxxx      ",
              "                                  ",
              "                                  "})
    
    mLink = createMousePointer(7, 0, {
              "      xx                          ",
              "     x..x                         ",
              "     x..x                         ",
              "     x..x                         ",
              "     x..x                         ",
              "     x..x                         ",
              "     x..xxx                       ",
              "     x..x..xxx                    ",
              " xx  x..x..x..x                   ",
              "x..x x..x..x..xxx                 ",
              "x...xx..x..x..x..x                ",
              " x..xx........x..x                ",
              " x...x...........x                ",
              "  x..x...........x                ",
              "  x..............x                ",
              "   x............x                 ",
              "   x............x                 ",
              "    x...........x                 ",
              "    x..........x                  ",
              "     x.x.x.x.x.x                  ",
              "     xx x x x xx                  "})

end procedure


ifdef WINDOWS then
    
	public include win32/win32.e
elsifdef LINUX then
    --Linux is not supported yet.
elsifdef OSX then
    --MacOS is not supported yet.
elsifdef UNIX then
    --Unix is not supported yet.
end ifdef
