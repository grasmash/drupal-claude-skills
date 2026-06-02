import Button from "@/components/button";

export default {
  title: "Components/Button",
  component: Button,
  argTypes: {
    variant: {
      control: "select",
      options: [
        "solid",
        "outline_dark",
        "outline_light",
        "ghost_neutral",
        "ghost_light",
        "link",
        "link_underline",
        "link_dark",
        "link_light",
        "nav_link_dark",
      ],
    },
  },
  parameters: {
    layout: "centered",
  },
};

export const Default = {
  args: {
    variant: "solid",
    text: "Button",
  },
};

export const Solid = {
  args: {
    variant: "solid",
    text: "Button",
  },
};

export const OutlineDark = {
  args: {
    variant: "outline_dark",
    text: "Button",
  },
};

export const OutlineLight = {
  args: {
    variant: "outline_light",
    text: "Button",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};

export const GhostNeutral = {
  args: {
    variant: "ghost_neutral",
    text: "Button",
  },
};

export const GhostLight = {
  args: {
    variant: "ghost_light",
    text: "Button",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};

export const Link = {
  args: {
    variant: "link",
    text: "Button",
  },
};

export const LinkUnderline = {
  args: {
    variant: "link_underline",
    text: "Button",
  },
};

export const LinkDark = {
  args: {
    variant: "link_dark",
    text: "Button",
  },
};

export const LinkLight = {
  args: {
    variant: "link_light",
    text: "Button",
  },
  decorators: [
    (Story) => (
      <div className="bg-slate-800 p-8">
        <Story />
      </div>
    ),
  ],
};
