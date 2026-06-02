import { cva } from "class-variance-authority";
import { cn } from "drupal-canvas";

const baseStyles = {
  disable: "disabled:pointer-events-none disabled:opacity-50",
  focus:
    "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:no-underline focus-visible:outline-primary-500 focus-visible:rounded-lg focus-visible:border-transparent",
  svg: "[&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0",
};

const buttonVariants = cva(
  cn(
    "inline-flex cursor-pointer items-center justify-center gap-2 rounded-lg px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors",
    baseStyles.disable,
    baseStyles.focus,
    baseStyles.svg,
  ),
  {
    variants: {
      variant: {
        solid:
          "border border-transparent bg-primary-600 text-white hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800",
        outline_dark:
          "border border-primary-600 text-primary-600 hover:border-primary-800 hover:bg-primary-100 hover:text-primary-800 focus:border-primary-800 focus:bg-primary-100 focus:text-primary-800 active:border-primary-900 active:bg-primary-200 active:text-primary-900",
        outline_light:
          "border border-white text-white hover:border-gray-300 hover:bg-gray-800 focus:border-gray-300 focus:bg-gray-800 active:border-gray-400 active:bg-gray-700",
        ghost:
          "border border-transparent text-primary-600 hover:bg-primary-100 hover:text-primary-800 focus:bg-primary-100 focus:text-primary-800 active:bg-primary-200 active:text-primary-900",
        ghost_neutral:
          "border border-transparent text-gray-600 hover:bg-gray-200 hover:text-gray-800 focus:bg-gray-200 focus:text-gray-800 active:bg-gray-300 active:text-gray-900",
        ghost_light:
          "border border-transparent text-white hover:border-gray-300 hover:bg-gray-800 focus:border-gray-300 focus:bg-gray-800 active:border-gray-400 active:bg-gray-700",
        link: "p-0 text-primary-600 hover:text-primary-800 hover:underline hover:underline-offset-2 focus:text-primary-800 active:text-primary-900",
        link_underline:
          "p-0 text-gray-900 underline underline-offset-3 hover:text-primary-600 focus:text-primary-600 active:text-primary-800",
        link_dark:
          "p-0 text-gray-900 hover:text-primary-600 hover:underline hover:underline-offset-3 focus:text-primary-600 active:text-primary-800",
        link_light:
          "p-0 text-white hover:text-primary-200 hover:underline hover:underline-offset-3 focus:text-primary-200 active:text-primary-300",
        nav_link_dark:
          "rounded-none border-s-0 border-transparent hover:border-primary-600 hover:text-primary-600 focus:border-primary-600 focus:text-primary-600 active:border-primary-800 active:text-primary-800 md:px-1 md:py-3",
      },
    },
    defaultVariants: {
      variant: "solid",
    },
  },
);

const Button = ({
  text = "",
  children = "",
  className = "",
  link = "#",
  variant,
  ...props
}) => {
  return (
    <a
      className={cn(buttonVariants({ variant }), className)}
      href={link}
      {...props}
    >
      {text}
      {children}
    </a>
  );
};

export default Button;
