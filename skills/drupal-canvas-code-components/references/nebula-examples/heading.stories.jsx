import Heading from "@/components/heading";

const exampleArgs = {
  heading: "Enter a heading...",
  textColor: "dark",
  headingElement: "h2",
  headingSize: "medium",
  layout: "left_aligned",
};

export default {
  title: "Components/Heading",
  component: Heading,
  argTypes: {
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
      options: ["small", "medium", "large", "extra_large"],
    },
    layout: {
      control: "select",
      options: ["left_aligned", "center_aligned", "right_aligned"],
    },
  },
};

export const Default = {
  args: exampleArgs,
};

export const ExtraLarge = {
  args: {
    ...exampleArgs,
    headingSize: "extra_large",
  },
};

export const Large = {
  args: {
    ...exampleArgs,
    headingSize: "large",
  },
};

export const Medium = {
  args: {
    ...exampleArgs,
    headingSize: "medium",
  },
};

export const Small = {
  args: {
    ...exampleArgs,
    headingSize: "small",
  },
};

export const CenterAligned = {
  args: {
    ...exampleArgs,
    layout: "center_aligned",
  },
};

export const RightAligned = {
  args: {
    ...exampleArgs,
    layout: "right_aligned",
  },
};

export const WithPreHeading = {
  args: {
    ...exampleArgs,
    preHeading: "Pre-heading text",
    heading: "Main heading text",
  },
};

export const LightOnDark = {
  args: {
    ...exampleArgs,
    textColor: "light",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};
