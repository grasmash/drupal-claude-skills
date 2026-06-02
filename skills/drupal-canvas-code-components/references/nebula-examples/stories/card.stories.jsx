import Card from "@/components/card";

const exampleArgs = {
  image: {
    src: "https://placehold.co/800x600@2x.png",
    alt: "Example image placeholder",
    width: 800,
    height: 600,
  },
  layout: "left_aligned",
  heading: "Feature or benefit",
  headingElement: "h3",
  text: "Help people become familiar with the organization and its offerings, creating a sense of connection and trust.",
  link: "/",
  linkVariant: "link",
};

export default {
  title: "Components/Card",
  component: Card,
  argTypes: {
    layout: {
      control: "select",
      options: ["left_aligned", "center_aligned", "right_aligned"],
    },
    textColor: {
      control: "select",
      options: ["Default", "dark", "light"],
    },
    headingElement: {
      control: "select",
      options: ["h1", "h2", "h3", "h4", "h5", "h6"],
    },
    linkVariant: {
      control: "select",
      options: ["solid", "outline_dark", "link", "link_underline"],
    },
    backgroundColor: {
      control: "color",
    },
    backgroundColorOnHover: {
      control: "color",
    },
  },
};

export const Default = {
  args: exampleArgs,
};

export const WithLink = {
  args: {
    ...exampleArgs,
    link: "/learn-more",
    linkLabel: "Learn more",
    linkVariant: "link",
  },
};

export const CenterAligned = {
  args: {
    ...exampleArgs,
    layout: "center_aligned",
  },
};

export const CustomColors = {
  args: {
    ...exampleArgs,
    backgroundColor: "#F0F9FF",
    backgroundColorOnHover: "#E0F2FE",
  },
};

export const WithSolidButton = {
  args: {
    ...exampleArgs,
    link: "/get-started",
    linkLabel: "Get Started",
    linkVariant: "solid",
  },
};
