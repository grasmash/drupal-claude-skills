import { cva } from "class-variance-authority";
import { cn, FormattedText } from "drupal-canvas";

const textVariants = cva("my-8", {
  variants: {
    textColor: {
      dark: "!text-black",
      light: "!text-white",
    },
    textSize: {
      extra_small: "text-xs",
      small: "text-sm",
      normal: "text-base/6",
      large: "text-lg/8",
      extra_large: "text-xl/8",
    },
    textShadow: {
      light: "text-shadow-sm",
      medium: "text-shadow-md",
      heavy: "text-shadow-lg",
    },
  },
});

const Text = ({ text, textSize, textColor, textShadow, className }) => {
  return (
    <FormattedText
      className={cn(
        textVariants({ textColor, textSize, textShadow }),
        className,
      )}
    >
      {text}
    </FormattedText>
  );
};

export default Text;
