import Button from "@/components/button";
import Hero from "@/components/hero";

const exampleArgs = {
  backgroundImage: {
    src: "https://placehold.co/1920x1080@2x.png",
    alt: "Example image placeholder",
    width: 1920,
    height: 1080,
  },
  layout: "left_aligned",
  preHeading: "Mission",
  headingElement: "h2",
  headingSize: "extra_large",
  heading: "This space deserves a hero.",
  text: "This is a space to welcome visitors to the site. Grab their attention with copy that clearly states what the site is about.",
  textColor: "dark",
};

export default {
  title: "Components/Hero",
  component: Hero,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    layout: {
      control: "select",
      options: ["left_aligned", "centered"],
    },
    textColor: {
      control: "select",
      options: ["dark", "light"],
    },
    headingSize: {
      control: "select",
      options: ["extra_large", "large", "medium", "small"],
    },
    headingElement: {
      control: "select",
      options: ["h1", "h2", "h3", "h4", "h5", "h6"],
    },
    darkenImage: {
      control: "boolean",
    },
  },
};

const SampleButtons = (
  <>
    <Button text="Get Started" variant="solid" link="#" />
    <Button text="Learn More" variant="outline_dark" link="#" />
  </>
);

const LightButtons = (
  <>
    <Button text="Get Started" variant="solid" link="#" />
    <Button text="Learn More" variant="outline_light" link="#" />
  </>
);

export const Default = {
  args: {
    ...exampleArgs,
    buttons: SampleButtons,
  },
};

export const Centered = {
  args: {
    ...exampleArgs,
    layout: "centered",
    buttons: SampleButtons,
  },
};

export const LightTextOnDarkImage = {
  args: {
    ...exampleArgs,
    textColor: "light",
    darkenImage: true,
    backgroundImage: {
      src: "https://placehold.co/1920x1080/1e293b/1e293b@2x.png",
      alt: "Dark background",
      width: 1920,
      height: 1080,
    },
    buttons: LightButtons,
  },
};

export const ExtraLargeHeading = {
  args: {
    ...exampleArgs,
    headingSize: "extra_large",
    heading: "Make a Bold Statement",
    buttons: SampleButtons,
  },
};

export const WithPreHeading = {
  args: {
    ...exampleArgs,
    preHeading: "Welcome",
    heading: "Build Something Amazing",
    text: "Create beautiful, responsive websites with our modern component library.",
    buttons: SampleButtons,
  },
};
