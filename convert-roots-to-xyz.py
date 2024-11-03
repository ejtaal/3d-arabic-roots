#!/usr/bin/env python3

import csv

known_locations = []
alt_rel_locations = [
    [.5, .5, .5],
    [0, .5, .5],
    [.5, 0, .5],
    [.5, .5, 0],
    [0, 0, .5],
    [.5, 0, 0],
    [0, .5, 0]
]

new_rows = []

with open('LL_3d_roots.csv', mode='r') as infile:
    reader = csv.reader(infile)


    # writer.writeheader()

    for row in reader:
        # print( "row1: ", row)    # with open('LL_3d_roots_new.csv', mode='w') as outfile:
        root = row[0]
        if root == 'Root':
            continue
        length = row[1]
        forms = row[2]
        forms_string = str(row[3:])
        
        # print( "row2: ", root, length, forms, forms_string)    # with open('LL_3d_roots_new.csv', mode='w') as outfile:
        
        l1 = root[0]
        x = ord( l1) - 1573
        l2 = root[1]
        y = ord( l2) - 1573
        z = 0
        if int(length) > 2:
            l3 = root[2]
            z = ord( l3) - 1573

        """
        Clean up UNICODE letter positions
        Alif madd is 4 before regular Alif
        
        position 4 is ta marbuta
        after wow is alif maksura
        
        """
        if x == -3: x = 1
        if y == -3: y = 1
        if z == -3: z = 1

        if x > 27: x -= 6
        if y > 27: y -= 6
        if z > 27: z -= 6

        if x > 4: x -= 1
        if y > 4: y -= 1
        if z > 4: z -= 1

        if x > 29: x = 29
        if y > 29: y = 29
        if z > 29: z = 29


        location = ( x, y, z)
        note = ''
        if location in known_locations:
            num = 0
            for alt_loc in alt_rel_locations:
                num += 1
                new_location = ( x+alt_loc[0], y + alt_loc[1], z + alt_loc[2])
                if new_location not in known_locations:
                    location = new_location
                    note += f'({num}) '
                    break

        note += f'{forms_string}'

        known_locations.append( location)
        # print( root, location, note)

        new_row = [
            root,
            x,
            y,
            z,
            length,
            forms,
            note
        ]
        new_rows.append( new_row)
        # print (new_row)

        
        # mydict = {rows[0]:rows[1] for rows in reader}

with open('LL_3d_roots_new.csv', mode='w') as outfile:
    outfile.write('root,x,y,z,length,forms,notes\n')
    # fieldnames = ['first_name', 'last_name']
    # writer = csv.DictWriter(outfile, fieldnames=fieldnames)

    writer = csv.writer(outfile) #, fieldnames=fieldnames)

    for row in new_rows:
        writer.writerow(row)


import json 
   
# # Define student_details dictionary
# student_details ={ 
#     "name" : "sathiyajith", 
#     "rollno" : 56, 
#     "cgpa" : 8.6, 
#     "phonenumber" : "9976770500"
# } 
   
# Convert and write JSON object to file
with open('LL_3d_roots_new.js', mode='w') as outfile:
    outfile.write('var ll_threed_roots_new = ')
    json.dump(new_rows, outfile, indent=4, ensure_ascii=False)
    # fieldnames = ['first_name', 'last_name']  .encode('utf8')
    # writer = csv.DictWriter(outfile, fieldnames=fieldnames)

    # writer = csv.writer(outfile) #, fieldnames=fieldnames)

    # for row in new_rows:
    #     writer.writerow(row)

    # outfile.write('}\n')
