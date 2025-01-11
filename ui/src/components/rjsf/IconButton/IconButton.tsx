import {
  ArrowDownIcon,
  ArrowUpIcon,
  DocumentDuplicateIcon,
  TrashIcon,
} from "@heroicons/react/24/outline"
import {
  FormContextType,
  IconButtonProps,
  RJSFSchema,
  StrictRJSFSchema,
  TranslatableString,
} from "@rjsf/utils"

interface ExtendedIconButtonProps<T, S extends StrictRJSFSchema, F extends FormContextType>
  extends IconButtonProps<T, S, F> {
  variant?: "danger" | "secondary"
}

export default function IconButton<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>({ icon, iconType, className, uiSchema, registry, disabled, variant, ...otherProps }: ExtendedIconButtonProps<T, S, F>) {
  const buttonClass = iconType === "block" ? "w-full" : ""
  const variantClass =
    variant === "danger"
      ? "bg-red-500 hover:bg-red-700 text-white"
      : disabled
      ? "bg-gray-100 text-gray-300"
      : "bg-gray-200 hover:bg-gray-500 text-gray-700"

  return (
    <button
      className={`grid justify-items-center px-4 py-2 text-base font-normal ${buttonClass} ${variantClass} ${className}`}
      disabled={disabled}
      {...otherProps}
    >
      {icon}
    </button>
  )
}

export function CopyButton<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: IconButtonProps<T, S, F>) {
  const {
    registry: { translateString },
  } = props
  return (
    <IconButton
      {...props}
      title={translateString(TranslatableString.CopyButton)}
      icon={<DocumentDuplicateIcon className="h-5 w-5" />}
      variant="secondary"
    />
  )
}

export function MoveDownButton<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: IconButtonProps<T, S, F>) {
  const {
    registry: { translateString },
  } = props
  return (
    <IconButton
      {...props}
      title={translateString(TranslatableString.MoveDownButton)}
      icon={<ArrowDownIcon className="h-5 w-5" />}
      variant="secondary"
    />
  )
}

export function MoveUpButton<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: IconButtonProps<T, S, F>) {
  const {
    registry: { translateString },
  } = props
  return (
    <IconButton
      {...props}
      title={translateString(TranslatableString.MoveUpButton)}
      icon={<ArrowUpIcon className="h-5 w-5" />}
      variant="secondary"
    />
  )
}

export function RemoveButton<
  T = any,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: IconButtonProps<T, S, F>) {
  const {
    registry: { translateString },
  } = props
  return (
    <IconButton
      {...props}
      title={translateString(TranslatableString.RemoveButton)}
      icon={<TrashIcon className="h-5 w-5" />}
      variant="danger"
    />
  )
}
