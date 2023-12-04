"""
Transform layer image to appropriate tiles. change perspective and set location
"""

from gimpfu import *
import math

TILE_TYPES = {
    'Sign' : {
        "ratio" : 1,
        "layers" : {
            'West' : [ 11, 135, 64, 108, 11, 187, 64, 160 ],
            'North' : [ 189, 108, 242, 134, 189, 160, 242, 187 ],
        },
    },
    # x: 3 ~ 63, 192 ~ 252
    # y: 7 ~ 191, 37 ~ 221
    'Sign-Wall' : {
        "ratio" : float(60) / 184,
        "layers" : {
            'West' : [ 3, 37, 63, 9, 3, 221, 63, 189 ],
            'North' : [ 192, 9, 252, 37, 192, 189, 252, 221 ],
        },
    },
}

TILE_TYPES_OPTIONS = tuple( x for x in TILE_TYPES )

### Options
COLOUR = "white"
COLOURINVERT = True
GRAYSCALE = True

def perspective_transform(img,drawable,tile_type_enum,sheet_index,padding):
    tile = TILE_TYPES[TILE_TYPES_OPTIONS[tile_type_enum]]

    ### make layer visible
    pdb.gimp_drawable_set_visible(drawable,True)

    if COLOURINVERT:
        pdb.gimp_invert(drawable)
    if GRAYSCALE:
        pdb.gimp_desaturate_full(drawable, DESATURATE_LUMINOSITY)

    ### auto crop layer image
    pdb.plug_in_autocrop_layer(img,drawable)

    ### resize layer to match tile ratio, add padding
    width, height = pdb.gimp_drawable_width(drawable), pdb.gimp_drawable_height(drawable)
    scaled_width, scaled_height = width + width * padding / 100, height + height * padding / 100
    scaled_width, scaled_height = max(scaled_width,math.ceil(scaled_height * tile["ratio"])), max(scaled_height,math.ceil(scaled_width / tile["ratio"]))
    pdb.gimp_layer_resize(drawable,scaled_width,scaled_height,int((scaled_width-width)/2),int((scaled_height-height)/2))

    # add each layer variation
    for k,v in tile["layers"].items():
        new_layer = pdb.gimp_layer_new_from_drawable(drawable,img)
        img.add_layer(new_layer, 0)
        pdb.gimp_item_set_name(new_layer,str(sheet_index) + "_" + k)
        pdb.gimp_item_transform_perspective(new_layer, *v)
        x = v[0] + (sheet_index % 8) * 128
        y = min(v[1],v[3]) + int(sheet_index/8) * 256
        pdb.gimp_layer_set_offsets(new_layer,x,y)

    pdb.gimp_image_remove_layer(img,drawable)
    pdb.gimp_displays_flush()

register(
    "perspective_transform", # function name
    "", # description
    "transform layer to iso sign region", # help
    "Poltergeist", # Author
    "Poltergeist", # Copyright
    "2023", # Date
    "<Image>/Filters/Util/Transform: Paint Sign", # menu
    "*", # drawables
    [
        (PF_OPTION,"type", "Tile type", 0, TILE_TYPES_OPTIONS),
        (PF_INT,"sheet_index","Index",0),
        (PF_FLOAT,"padding","Padding pc",1),
    ], #options
    [], #returns
    perspective_transform,
)

main()