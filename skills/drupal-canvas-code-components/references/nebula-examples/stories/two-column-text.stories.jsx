import Button from "@/components/button";
import TwoColumnText from "@/components/two_column_text";

const exampleArgs = {
  image: {
    src: "https://placehold.co/800x600@2x.png",
    alt: "Example image placeholder",
    width: 800,
    height: 600,
  },
  layout: "left_aligned",
  preHeading: "Mission",
  heading: "This space deserves a hero.",
  headingElement: "h2",
  headingSize: "large",
  text: "This is a space to welcome visitors to the site. Grab their attention with copy that clearly states what the site is about.",
  textColor: "dark",
};

export default {
  title: "Components/Two Column Text",
  component: TwoColumnText,
  argTypes: {
    layout: {
      control: "select",
      options: ["left_aligned", "centered"],
    },
    textColor: {
      control: "select",
      options: ["dark", "light"],
    },
    headingElement: {
      control: "select",
      options: ["h1", "h2", "h3", "h4", "h5", "h6"],
    },
    headingSize: {
      control: "select",
      options: ["extra_large", "large", "medium", "small"],
    },
  },
};

const SampleButtons = (
  <>
    <Button text="Primary Action" variant="solid" link="#" />
    <Button text="Secondary" variant="outline_dark" link="#" />
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

export const WithPreHeading = {
  args: {
    ...exampleArgs,
    preHeading: "Welcome",
    heading: "Build something amazing",
    text: "Create beautiful, responsive websites with our component library. Designed for developers who value clean code and modern design.",
    buttons: SampleButtons,
  },
};

export const LightOnDark = {
  args: {
    ...exampleArgs,
    textColor: "light",
    buttons: (
      <>
        <Button text="Get Started" variant="solid" link="#" />
        <Button text="Learn More" variant="outline_light" link="#" />
      </>
    ),
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800">
        <Story />
      </div>
    ),
  ],
};

export const WithoutImage = {
  args: {
    layout: "left_aligned",
    heading: "Simple and Clean",
    headingElement: "h2",
    headingSize: "large",
    text: "Sometimes you just need text without an image. This layout works great for that.",
    textColor: "dark",
    buttons: SampleButtons,
  },
};
