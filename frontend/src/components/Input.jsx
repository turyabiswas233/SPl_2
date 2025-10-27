import React from "react";
import { FaEye } from "react-icons/fa";
import { PiEyeClosedDuotone } from "react-icons/pi";
function Input({
  icon,
  title,
  type,
  id,
  name,
  placeholder,
  autoComplete,
  required,
  value,
  handleChange,
}) {
  const [show, setShow] = React.useState(false);
  if (type.toLowerCase() === "password")
    return (
      <div className="bg-white shadow-lg shadow-gray-200 flex items-center justify-between gap-4 w-full p-4 rounded-xl outline-1 outline-gray-300/50">
        {icon}
        <div className="grid w-full">
          <label className="text-xs poppins-regular" htmlFor={name}>
            {title}
          </label>
          <input
            className="outline-0 poppins-bold text-base w-full"
            type={show ? "text" : "password"}
            placeholder={placeholder || "*********"}
            id={id}
            name={name}
            autoComplete={autoComplete || "off"}
            required={required || false}
            value={value}
            onChange={handleChange}
          />
        </div>
        <button type="button" onClick={() => setShow(!show)}>
          <div className="grid h-7 rounded-full overflow-y-hidden">
            <PiEyeClosedDuotone
              size={25}
              style={{
                transition: `transform 0.3s ease-in-out`,
                transform: show ? `translateY(-25px)` : `translateY(0px)`,
              }}
            />
            <FaEye
              size={25}
              style={{
                transition: `transform 0.3s ease-in-out`,
                transform: show ? `translateY(-25px)` : `translateY(0px)`,
              }}
            />
          </div>
        </button>
      </div>
    );
  return (
    <div className="bg-white shadow-lg shadow-gray-200 flex items-center justify-between gap-4 w-full p-4 rounded-xl outline-1 outline-gray-300/50">
      {icon}
      <div className="grid w-full">
        <label className="text-xs poppins-regular" htmlFor={name}>
          {title}
        </label>
        <input
          className="outline-0 poppins-bold text-base w-full"
          type={type}
          placeholder={placeholder || ""}
          id={id}
          name={name}
          autoComplete={autoComplete || "off"}
          required={required || false}
          value={value}
          onChange={handleChange}
        />
      </div>
    </div>
  );
}

export default Input;
