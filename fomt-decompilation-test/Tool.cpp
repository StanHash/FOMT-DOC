
struct ToolDefinition {
    const char* name;
    unsigned short unk4;
    const char* desc;
};

extern const ToolDefinition gToolTable[];

struct Tool {
    Tool(unsigned index);

    unsigned getIndex() const;
    const char* getName() const;
    unsigned get_800DB60() const;
    const char* getDesc() const;

private:
    unsigned char mIndex;
};

Tool::Tool(unsigned index)
    : mIndex(index) {}

unsigned Tool::getIndex() const {
    return mIndex;
}

const char* Tool::getName() const {
    unsigned index = mIndex;
    bool notBroken = (index < 0x51);

    if (notBroken)
        return gToolTable[mIndex].name;

    return "Broken Tool";
}

unsigned Tool::get_800DB60() const {
    unsigned index = mIndex;
    bool notBroken = (index < 0x51);

    if (notBroken)
        return gToolTable[index].unk4;

    return 0x1C9;
}

const char* Tool::getDesc() const {
    unsigned index = mIndex;
    bool notBroken = (index < 0x51);    

    if (notBroken)
        return gToolTable[mIndex].desc ? gToolTable[mIndex].desc : "No Explanation";

    return "No Explanation";
}
