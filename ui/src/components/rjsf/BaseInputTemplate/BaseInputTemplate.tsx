import { ChangeEvent, FocusEvent } from "react"
import {
  BaseInputTemplateProps,
  FormContextType,
  RJSFSchema,
  StrictRJSFSchema,
} from "@rjsf/utils"

export default function BaseInputTemplate<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any
>({
  id,
  placeholder,
  required,
  readonly,
  disabled,
  type,
  value,
  onChange,
  onBlur,
  onFocus,
  autofocus,
  options,
  schema,
  rawErrors = [],
  children,
  extraProps,
}: BaseInputTemplateProps<T, S, F>) {
  const inputProps = {
    id,
    placeholder,
    disabled: disabled || readonly,
    required,
    type,
    value,
    onChange: ({ target: { value } }: ChangeEvent<HTMLInputElement>) =>
      onChange(value === "" ? options.emptyValue : value),
    onBlur: ({ target: { value } }: FocusEvent<HTMLInputElement>) =>
      onBlur(id, value),
    onFocus: ({ target: { value } }: FocusEvent<HTMLInputElement>) =>
      onFocus(id, value),
    autoFocus: autofocus,
    ...extraProps,
  }

  return (
    <input
      className="flex h-10 w-full rounded-md border border-input bg-slate-100 px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      {...inputProps}
    />
  )
}
