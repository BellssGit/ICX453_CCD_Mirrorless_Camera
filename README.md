# DIY APS-C Size CCD Sensor Mirrorless Camera

![cover1.jpg](https://s2.loli.net/2025/05/01/phamgYfiQExT3yq.jpg)

Blog about this project: https://www.emoe.xyz/diy_ccd_camera/ (Chinese)

## Hardware

1. FPGA Core board --- [Open source ZYNQ7000 Board from oshwhub.com](https://oshwhub.com/z_star/zynq7020-core-board-and-various-rf-modules)
2. CCD Base board --- "CCD_Sensor_ZYNQ_Based_Board" Folder (KiCAD >= 8)
3. Handle and Lens Mount --- "3d_model" Folder (FreeCAD >= 1.0)

## Software

1. "pixel_rearrange.py" for pixel re-arrangement
2. GIMP for gamma correction
3. Fitswork4 for debayer 
4. Photoshop and the "CCD_CameraRAW_Preset" for color grading
5. Vivado 2018.3 and "CCD_Cam_Vivado_workspace.7z" for both PL and PS source code

   Note: Due to Github file size limitation and I dont want to upload the whole workspace folder (because that is a mess), So the workspace is split into two smaller compressed files.


Some sample photo

![s1.jpg](https://s2.loli.net/2025/05/01/i31rWQqyGZdVMcH.jpg)

![s2.jpg](https://s2.loli.net/2025/05/01/ZOT19nExtBRQgfS.jpg)
