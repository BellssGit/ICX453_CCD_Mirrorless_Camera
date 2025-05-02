import os
import struct
from PIL import Image
import numpy as np


#offset = int(6248 * 2 + 57 * 2 + 6248 * 2) #This offset will cause GRBG color filter, and dosent left black line
offset = int(55 * 2) # This offset will cause GBRG color filter, which is correct but will left some black line in the image
# I guess the second one is better? idk, will decide it later

line_size = 6248

for f in range(1):
    file_name = './color_check'

    bin_file = open(f'{file_name}.bin', 'rb')
    size = os.path.getsize(f'{file_name}.bin')
    print(size/(line_size))

    offset = int(55 * 2)
    i = 1

    width1 = line_size - 148
    height1 = 1024

    width2 = 3000
    height2 = 2000

    width3 = 240
    height3 = 160

    rolling_const = 0
    rolling_vari = 0

    im = Image.new('I', (width2, height2))
    pix = im.load()
    pixel = 0

    for i in range(int(height2/2)) :
        bin_file.seek(offset)
        bin_data = bin_file.read(int((line_size - 148)*2))

        offset = offset + width1 * 2 + 147*2
        value = struct.unpack('<6100H', bin_data)

        temp_array = np.array(value)

        if(i % 2 == 0):
            temp_array2 = temp_array[3:6003]
        else:
            temp_array2 = temp_array[5:6005]

        pixel = 0
        cnt = 0

        for k in range(int(6000)):

            if(k != 0 and k % 2 == 0):
                pixel = pixel + 1

            if(cnt == 0):
                pix[pixel, i * 2] = int(temp_array2[k])
                cnt = cnt + 1
            elif (cnt == 1):
                pix[pixel, i * 2 + 1] = int(temp_array2[k])
                cnt = cnt + 1
            elif (cnt == 2):
                pix[pixel, i * 2 + 1] = int(temp_array2[k])
                cnt = cnt + 1
            elif (cnt == 3):
                pix[pixel, i * 2] = int(temp_array2[k])
                cnt = 0

    rot_img = im.transpose(Image.ROTATE_180)
    rot_img.save(f'{file_name}.png')
    im.close()
    rot_img.close()
    bin_file.close()
