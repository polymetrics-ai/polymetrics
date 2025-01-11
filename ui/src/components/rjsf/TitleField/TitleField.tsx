import {
  FormContextType,
  getUiOptions,
  RJSFSchema,
  StrictRJSFSchema,
  TitleFieldProps,
} from "@rjsf/utils"

export default function TitleField<
  T extends Record<string, unknown> = Record<string, unknown>,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = FormContextType,
>({ id, title, uiSchema }: TitleFieldProps<T, S, F>) {
  const uiOptions = getUiOptions<T, S, F>(uiSchema)

  return (
    <div id={id} className="my-1">
      <h5 className="mb-1 text-xl font-medium leading-tight">
        {uiOptions.title || title}
      </h5>
      <hr className="mb-1 border-t border-muted" aria-label="Section divider" />
    </div>
  )
}
