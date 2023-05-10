#coding=utf-8
'''
author : QyLey
description:
AutoDocSV(Auto document for SystemVerilog) can generate a 
template ReST document for system verilog module
'''

import os, re
import sys
import math

def rstTitle(moduleName):
    s = moduleName + '''
------------------------------------------------
'''
    return s
    
def rstDescription(description):
    s = description + '''

'''
    return s
    
def rstParameters(Parameters):
    s = '''
Parameters
````````````````````````````````````````````````

'''

    if Parameters :
        s +='''
.. csv-table::
 :header: "parameter", "datatype", "range", "description"
 :widths: 2, 2, 2, 4
 
 '''
   
        for p in Parameters:
            s += '"' + p['name'] + '", "' + p['dtype'] + '", "' + p['range'] + '", "' + p['desc'] + '''"
 '''
    else :
        s +='''
    No Parameter
'''

    s += '''

'''
    return s
    
def rstIOs(ios):
    s = '''
IOs
````````````````````````````````````````````````

.. csv-table::
 :header: "signal", "I/O", "width", "description"
 :widths: 2, 1, 2, 3
   
 '''
   
    for io in ios:
        s += '"' + io['name'] + '", "' + io['way'] + '", "' + io['width'] + '", "' + io['desc'] + '''"
 '''

    s += '''

'''
    return s
    
def removeRedundantBlank(string):
    newLine = re.sub("^(\s*)","",string)
    newLine = re.sub("(\s*)$","",newLine)
    newLine = re.sub("(\s+)"," ",newLine)
    return newLine
    
def removeComma(string):
    newLine = re.sub(",","",string)
    return newLine
    
def deAnnotation(string):
    newLine = re.sub("/\*","",string)
    newLine = re.sub("\*/","",newLine)
    newLine = removeRedundantBlank(newLine)
    newLine = re.sub("</br>",'''

''',newLine)
    return newLine
    
def svParser(filePath):
    rst = ""
    with open(filePath) as f:
        svCode = f.read()
        #print(svCode)
        fileLineNum = len(svCode)
        
        # Search AutoDocSV annotation
        annotationObj = re.search(r'/\*----------.+----------\*/',svCode,re.M|re.S)
        if not annotationObj:
            print("No AutoDocSV annotation found.")
            return
        description = annotationObj.group()
        description = re.sub(r"/\*-+\s+","",description)
        description = re.sub(r"\s+-+\*/","",description)
        
        # Search module definition
        moduleDefObj = re.search(r'module (.+?)\((.+?)\);',svCode[annotationObj.end():],re.M|re.S)
        moduleDef = moduleDefObj.group()
        if not moduleDefObj:
            print("No module found.")
            return
        
        # Search module name
        moduleNameObj = re.search(r'module(\s+)(.+?)(\s*)[#\(]',moduleDef,re.M|re.S)
        if not moduleNameObj:
            print("No module name found.")
            return
        moduleName = moduleNameObj.group()
        moduleName = re.sub(r"module(\s+)","",moduleName)
        moduleName = re.sub(r"(\s*)[#\(]$","",moduleName)
        
        # Search Parameters
        parametersObj = re.search(r'#(\s*)\(((/\*(.*?)\*/)|(\(.*?\))|(.))*?\)',moduleDef,re.M|re.S)
        if not parametersObj:
            parameters = ""
            parametersEnd = 0
        else : 
            parameters = parametersObj.group()
            parametersEnd = parametersObj.end()
        
        # Search IOs
        iosObj = re.search(r"\(((/\*.*?\*/)|(.))*?\);$",moduleDef[parametersEnd:],re.M|re.S)
        if not iosObj:
            ios = ""
        else : 
            ios = iosObj.group()
        
        #Parse Parameters:
        parameterPattern = re.compile(r'((/\*.*?\*/)*?(\s)*parameter.+?\n)',re.M|re.S)
        dividedParam = parameterPattern.findall(parameters)

        paramsTable = []
        # (/*[desc @range: ["range"]]*/) parameter [dtype] [name] [= default_value] [,]
        for n in range(len(dividedParam)):
            param = {}
            # remove long blank
            newLine = removeRedundantBlank(dividedParam[n][0])
            # Parse parameter annotation
            paramAnnot = re.search("\/*.*?\*/",newLine,re.M|re.S)
            if paramAnnot :
                paramAnnotSplit = re.split("@[Rr]ange:", paramAnnot.group())
                param["desc"] = deAnnotation(paramAnnotSplit[0])
                if len(paramAnnotSplit)>1 :
                    param["range"] = deAnnotation(paramAnnotSplit[1])
                    param["range"] = re.sub(r'[\"\']',"",param["range"])
                else : 
                    param["range"] = "ndef"
            else :
                param["desc"] = "ndef"
                param["range"] = "ndef"
            # Parse parameter definition
            paramDef = re.search("parameter.*?(=.*)*?$",newLine,re.M|re.S)
            if paramDef :
                paramDef = re.split("=",paramDef.group())
                paramDef = removeRedundantBlank(paramDef[0])
                paramDefSplit = re.split(" ", paramDef)
                param["name"] = paramDefSplit[-1]
                if len(paramDefSplit)>2 :
                    param["dtype"] = ""
                    for k in paramDefSplit[1:-1]:
                        param["dtype"] = param["dtype"] + k + ' '
                    param["dtype"] = removeRedundantBlank(param["dtype"])
                else : 
                    param["dtype"] = "int(default)"
            else :
                print('Error when parsing paramter', n)
                return
            param["name"] = removeComma(param["name"])
            paramsTable.append(param)
            print(param)
            
        
        # Parse io def
        ioPattern = re.compile(r'((/\*.*?\*/)*?(\s)*((input)|(output)|(inout)).+?\n)',re.M|re.S)
        dividedIOs = ioPattern.findall(ios)
        
        iosTable = []
        for n in range(len(dividedIOs)):
            io = {}
            # remove long blank
            newLine = removeRedundantBlank(dividedIOs[n][0])
            # Parse io annotation
            ioAnnot = re.search("\/*.*?\*/",newLine,re.M|re.S)
            if ioAnnot :
                io["desc"] = deAnnotation(ioAnnot.group())
            else :
                io["desc"] = "ndef"
            # Parse io definition
            ioDef = re.search("((input)|(output)|(inout))([^/])+?$",newLine,re.M|re.S)
            if ioDef :
                ioDef = removeRedundantBlank(ioDef.group())
                ioDefSplit = re.split(" ", ioDef)
                io["way"] = ioDefSplit[0]
                if len(ioDefSplit)>1 :
                    io["name"] = ioDefSplit[-1]
                else :
                    print('Error when parsing io', n)
                    return
                if len(ioDefSplit)>2 :
                    io["width"] = ""
                    for k in ioDefSplit[1:-1]:
                        io["width"] = io["width"] + k + ' '
                    io["width"] = removeRedundantBlank(io["width"])
                else : 
                    io["width"] = "bit"
            else :
                print('Error when parsing io', n)
                return
            io["name"] = removeComma(io["name"])
            iosTable.append(io)
            print(io)
            
        rst += rstTitle(moduleName)
        rst += rstDescription(description)
        rst += rstParameters(paramsTable)
        rst += rstIOs(iosTable)
        # create file pointer
        file_name = moduleName + ".rst"
        fp = open(file_name, mode='w')
        fp.write(rst)
        fp.close()
    return
        
        

def main(argv):
    if(argv[1]!=""):
        svParser(argv[1])

if __name__ == "__main__":
    main(sys.argv)