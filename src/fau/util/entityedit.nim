import polymorph, ../../core, ../g2/imgui
import sequtils, strutils

onEcsBuilt:
  var 
    entityEditorShown: bool
    searchText: string = ""

  import sequtils, strutils

  proc showEntityEditor*(toggleKey = keyF2) =
    if toggleKey.tapped:
      entityEditorShown = not entityEditorShown

    if entityEditorShown:
    
      igBegin("Entities", addr entityEditorShown)
      
      igInputTextWithHint("##Search", "Search", searchText)

      if entityCount() != 0:
        for i in 0 ..< entityStorage.nextEntityId.int:
          let ent = (i.EntityId).makeRef

          if not ent.alive: continue

          let systemStr = ent.listSystems()

          if (searchText == "" or systemStr.toLowerAscii.contains(searchText.toLowerAscii)) and igCollapsingHeader(cstring($ent.entityId.int & " [" & (systemStr.split('\n').mapIt(it.split(' ')[0])).join(" ")[0..^2] & "]")):
            igPushID(ent.entityId.int32)
            igPushItemWidth(300f)

            if ent.componentCount > 0:
              for compRef in ent.components:
                caseComponent(compRef.typeId):
                  #TODO: delete button

                  igSeparator()

                  var data = componentInstanceType()(compRef.index.int).access

                  var fieldCount = 0
                  for _, _ in data.fieldpairs:
                    fieldCount.inc
                  
                  let disabled = fieldCount == 0

                  igBeginDisabled(disabled)
                  
                  if igTreeNode($typeof(data)):

                    template editField(field: string, value: untyped): untyped =
                      let fieldLabel {.used.} = field.cstring

                      when value is int or value is int32:
                        igInputInt(fieldLabel, addr value)
                      elif value is float32:
                        igInputFloat(fieldLabel, addr value)
                      elif value is Vec2:
                        igInputFloat2(fieldLabel, value)
                      elif value is Vec2i:
                        igInputInt2(fieldLabel, value)
                      elif value is Rect:
                        igInputFloat4(fieldLabel, value)
                      elif value is Color:
                        igColorEdit4(fieldLabel, value)
                      elif value is bool:
                        igCheckbox(fieldLabel, addr value)
                      elif value is string:
                        igInputText(fieldLabel, value)
                      elif value is ref object:
                        igText(($value[]).cstring)
                      elif value is EntityRef:
                        igText((field & " Entity#" & $value.entityId.int).cstring)
                      elif value is array or value is seq:
                        if igTreeNode(field):
                          for i, arrayval in value.mpairs:
                            editField($i, arrayval)
                          
                          igTreePop()
                      elif value is object:
                        if igTreeNode(fieldLabel):
                          for ofield, ovalue in value.fieldpairs:
                            editField(ofield, ovalue)
                          igTreePop()
                      elif compiles($value):
                        igText((field & ": " & $value).cstring)
                      else:
                        igText(fieldLabel)

                    template listFields(obj: untyped): untyped = 
                      for field, value in obj.fieldpairs:
                        editField(field, value)
                        
                    listFields(data)

                    ent.addOrUpdate data

                    igTreePop()
                  
                  igEndDisabled()

            igPopItemWidth()
            igPopID()
        

      igEnd()