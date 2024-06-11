import polymorph, ../../core, ../g2/imgui
import sequtils, strutils

onEcsBuilt:
  var entityEditorShown: bool

  import sequtils, strutils

  proc showEntityEditor*(toggleKey = keyF2) =
    if toggleKey.tapped:
      entityEditorShown = not entityEditorShown

    if entityEditorShown:
    
      igBegin("Entities", addr entityEditorShown)

      if entityCount() != 0:
        for i in 0 ..< entityStorage.nextEntityId.int:
          let ent = (i.EntityId).makeRef

          if ent.alive and igCollapsingHeader($ent.entityId.int & " [" & (ent.listSystems().split('\n').mapIt(it.split(' ')[0])).join(" ")[0..^2] & "]"):
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

                    template listFields(obj: untyped): untyped = 
                      for field, value in obj.fieldpairs:
                        let fieldLabel = field.cstring

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
                          igText($value[])
                        elif value is object:
                          if igTreeNode(field):
                            listFields(value)
                            igTreePop()
                        elif compiles($value):
                          igText(field & ": " & $value)
                        else:
                          igText(field)
                        
                    listFields(data)

                    ent.addOrUpdate data

                    igTreePop()
                  
                  igEndDisabled()

            igPopItemWidth()
            igPopID()
        

      igEnd()