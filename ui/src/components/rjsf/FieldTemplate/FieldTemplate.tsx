import {
  FieldTemplateProps,
  FormContextType,
  RJSFSchema,
  StrictRJSFSchema,
} from "@rjsf/utils"

export default function FieldTemplate<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any
>({
  id,
  children,
  displayLabel,
  label,
  description,
  errors,
  help,
  hidden,
  required,
  rawErrors,
}: FieldTemplateProps<T, S, F>) {
  if (hidden) {
    return <div className="hidden">{children}</div>
  }

  const isRootField = id === "root"

  return (
    <div className="mb-2 bg-slate-100 rounded-md p-2">
      {displayLabel && (
        <label htmlFor={id} className="mb-1 block text-sm font-semibold tracking-tighter">
          {label}
          {required && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}
      {description && !isRootField && (
        <p className="text-xs text-slate-500 mb-1">{description}</p>
      )}
      {children}
      {errors && (
        <div className="mt-1 text-xs text-red-500">{errors}</div>
      )}
      {help && (
        <p className="mt-1 text-xs text-slate-500">{help}</p>
      )}
    </div>
  )
}
