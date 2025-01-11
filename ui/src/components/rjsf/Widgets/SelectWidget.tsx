import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  FormContextType,
  RJSFSchema,
  StrictRJSFSchema,
  WidgetProps,
} from "@rjsf/utils"

export default function SelectWidget<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any
>({
  id,
  options,
  value,
  required,
  disabled,
  readonly,
  onChange,
  onBlur,
  onFocus,
  placeholder,
}: WidgetProps<T, S, F>) {
  const { enumOptions, enumDisabled } = options

  const handleChange = (value: string) => {
    onChange(value === "" ? options.emptyValue : value)
  }

  return (
    <Select
      value={value}
      onValueChange={handleChange}
      disabled={disabled || readonly}
    >
      <SelectTrigger className="w-full bg-background border border-input ring-offset-background focus:ring-2 focus:ring-ring focus:ring-offset-2 mb-1">
        <SelectValue placeholder={placeholder} />
      </SelectTrigger>
      <SelectContent 
        className="bg-background border border-input"
        position="popper"
        sideOffset={4}
      >
        {(enumOptions as any[]).map(({ value, label }, i) => (
          <SelectItem
            key={i}
            value={value}
            disabled={enumDisabled && (enumDisabled as any[]).indexOf(value) !== -1}
            className="py-2.5 hover:bg-accent focus:bg-accent"
            hideIndicator
          >
            {label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
} 