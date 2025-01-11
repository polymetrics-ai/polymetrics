import { FormContextType, RJSFSchema, StrictRJSFSchema, WidgetProps } from "@rjsf/utils"
import SelectWidget from "./SelectWidget"

export function generateWidgets<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any
>() {
  return {
    SelectWidget,
  }
}

export default generateWidgets()
