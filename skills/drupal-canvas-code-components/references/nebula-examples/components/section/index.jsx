import { cva } from "class-variance-authority";

const sectionVariants = cva("m-auto my-8 px-4", {
  variants: {
    width: {
      normal: "max-w-2xl",
      wide: "max-w-4xl",
    },
  },
});

const Section = ({ width, content }) => {
  return <div className={sectionVariants({ width })}>{content}</div>;
};

export default Section;
