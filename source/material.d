import raylib;

/// A material is the smooth-terrain version of a block.
/// AIR is empty. DIRT and ROCK are solid. Draw color comes from this type.
enum MaterialType {
    AIR,
    DIRT,
    ROCK,
}

int getMaterialID(MaterialType materialType) {
    int idOut = 0;
    switch(materialType) {
        case MaterialType.AIR:
            idOut = 0;
            break;
        case MaterialType.DIRT:
            idOut = 1;
            break;
        case MaterialType.ROCK:
            idOut = 2;
            break;
        default:
            break;
    }
    return idOut;
}

bool materialIsSolid(int id) {
    return id != getMaterialID(MaterialType.AIR);
}

/// Brown dirt, gray rock. AIR has no terrain color.
Color getMaterialColor(int id) {
    if(id == getMaterialID(MaterialType.DIRT))
        return Colors.BROWN;
    if(id == getMaterialID(MaterialType.ROCK))
        return Colors.GRAY;
    return Color(0, 0, 0, 0);
}
